import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'package:imker/features/projects/domain/project_failure.dart';

import '../../domain/models/project_task.dart';
import '../../domain/models/subtask.dart';
import '../../domain/models/task_comment.dart';
import '../../domain/models/task_status.dart';
import '../../domain/repositories/i_task_repository.dart';
import '../datasources/i_task_data_source.dart';

class TaskRepository with UiLoggy implements ITaskRepository {
  TaskRepository(this._source);

  final ITaskDataSource _source;

  @override
  Future<List<ProjectTask>> getTasks(String projectId) async {
    final rows = await _guard(() => _source.readTasks(projectId));
    return rows.map(_toTask).toList();
  }

  @override
  Future<ProjectTask> createTask({
    required String projectId,
    required String title,
    String description = '',
  }) async {
    final row = await _guard(
      () => _source.createTask({
        'project_id': projectId,
        'title': title,
        'description': description,
        'status': TaskStatus.todo.name,
      }),
    );
    await _syncProgress(projectId);
    return _toTask(row);
  }

  @override
  Future<ProjectTask> updateTaskStatus({
    required ProjectTask task,
    required TaskStatus status,
  }) async {
    await _guard(() => _source.updateTask(task.id, {'status': status.name}));
    await _syncProgress(task.projectId);
    return task.copyWith(status: status);
  }

  @override
  Future<ProjectTask> reserveTask({
    required ProjectTask task,
    required String userId,
  }) async {
    final rows = await _guard(() => _source.readTasks(task.projectId));
    final current = rows.map(_toTask).where((t) => t.id == task.id).firstOrNull;
    if (current == null) {
      throw const ProjectFailure('La tarea ya no existe.');
    }
    final taken = current.assigneeId != null && current.assigneeId != userId;
    if (current.status != TaskStatus.todo || taken) {
      throw const ProjectFailure(
        'Esta tarea ya fue reservada por otra persona.',
      );
    }
    await _guard(
      () => _source.updateTask(task.id, {
        'assignee_id': userId,
        'status': TaskStatus.doing.name,
      }),
    );
    // Pasar de todo a doing no cambia cuántas tareas están terminadas, así
    // que el progreso del proyecto sigue igual.
    return current.copyWith(status: TaskStatus.doing, assigneeId: userId);
  }

  @override
  Future<ProjectTask> saveTaskProgress({
    required ProjectTask task,
    required String description,
    required List<Subtask> subtasks,
  }) async {
    final status = ProjectTask.statusAfterSaving(task.status, subtasks);
    await _guard(
      () => _source.updateTask(task.id, {
        'description': description,
        'checklist': [for (final s in subtasks) s.toJson()],
        'status': status.name,
      }),
    );
    // Solo si cambió terminada/no terminada se mueve el progreso del proyecto.
    if (status.name != task.status.name &&
        (status == TaskStatus.done || task.status == TaskStatus.done)) {
      await _syncProgress(task.projectId);
    }
    return task.copyWith(
      description: description,
      subtasks: List.unmodifiable(subtasks),
      status: status,
    );
  }

  @override
  Future<List<TaskComment>> getComments(ProjectTask task) async {
    final rows = await _guard(() => _source.readContributions(task.id));
    final comments = rows.map(_toComment).toList();
    // Los sin fecha al final; el resto del más nuevo al más viejo.
    comments.sort((a, b) {
      final ad = a.createdAt;
      final bd = b.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return comments;
  }

  @override
  Future<TaskComment> addComment({
    required ProjectTask task,
    required String userId,
    required String body,
  }) async {
    final row = await _guard(
      () => _source.createContribution({
        'user_id': userId,
        'project_id': task.projectId,
        'task_id': task.id,
        'description': body,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return _toComment(row);
  }

  @override
  Future<int> releaseUnfinishedTasks({
    required String projectId,
    required String userId,
  }) async {
    final rows = await _guard(() => _source.readTasks(projectId));
    final mine = rows
        .map(_toTask)
        .where((t) => t.assigneeId == userId && !t.isDone);
    var released = 0;
    for (final task in mine) {
      await _guard(
        () => _source.updateTask(task.id, {
          'assignee_id': null,
          'status': TaskStatus.todo.name,
        }),
      );
      released++;
    }
    return released;
  }

  @override
  Future<void> deleteTask(ProjectTask task) async {
    await _guard(() => _source.deleteTask(task.id));
    await _syncProgress(task.projectId);
  }

  @override
  Future<double> recalculateProgress(String projectId) async {
    final tasks = await getTasks(projectId);
    final progress = ProjectTask.progressOf(tasks);
    await _guard(() => _source.writeProjectProgress(projectId, progress));
    return progress;
  }

  /// El progreso es un derivado: si no se pudo actualizar, la tarea que sí se
  /// guardó no se deshace. Se avisa en el log y el siguiente cambio (o un
  /// [recalculateProgress] explícito) lo deja bien.
  Future<void> _syncProgress(String projectId) async {
    try {
      await recalculateProgress(projectId);
    } catch (e) {
      loggy.warning('No se pudo actualizar el progreso de $projectId: $e');
    }
  }

  ProjectTask _toTask(Map<String, dynamic> row) => ProjectTask(
    id: (row['_id'] ?? row['id'])?.toString() ?? '',
    projectId: row['project_id']?.toString() ?? '',
    title: (row['title'] ?? '').toString(),
    description: (row['description'] ?? '').toString(),
    status: TaskStatus.fromName(row['status']?.toString()),
    assigneeId: _nonEmpty(row['assignee_id']),
    subtasks: _decodeChecklist(row['checklist']),
  );

  TaskComment _toComment(Map<String, dynamic> row) => TaskComment(
    id: (row['_id'] ?? row['id'])?.toString() ?? '',
    userId: row['user_id']?.toString() ?? '',
    body: (row['description'] ?? '').toString(),
    createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? ''),
  );

  /// `checklist` es jsonb: Roble lo devuelve como lista o como texto JSON.
  /// Lo que no calza (null, objeto, entradas rotas) da una lista vacía o se
  /// descarta: una fila mal guardada no debe tumbar el tablero.
  List<Subtask> _decodeChecklist(Object? raw) {
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return const [];
      try {
        return _decodeChecklist(jsonDecode(text));
      } on FormatException {
        return const [];
      }
    }
    if (raw is! List) return const [];
    return [for (final entry in raw) ?Subtask.tryFromJson(entry)];
  }

  String? _nonEmpty(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RobleApiNetworkException {
      throw const ProjectFailure('Sin conexión. Verifica tu red.');
    } on RobleApiTimeoutException {
      throw const ProjectFailure(
        'La solicitud tardó demasiado. Intenta de nuevo.',
      );
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 403) {
        throw const ProjectFailure('No tienes permiso para hacer esto.');
      }
      loggy.error('task HTTP ${e.statusCode}: ${e.message}');
      throw ProjectFailure(e.message);
    } on RobleApiException catch (e) {
      loggy.error('task error: $e');
      throw const ProjectFailure('Error del servidor. Intenta de nuevo.');
    }
  }
}
