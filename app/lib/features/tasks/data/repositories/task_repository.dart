import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'package:imker/core/utils/clock.dart';
import 'package:imker/features/projects/domain/project_failure.dart';

import '../../domain/models/member_stay.dart';
import '../../domain/models/project_task.dart';
import '../../domain/models/subtask.dart';
import '../../domain/models/task_comment.dart';
import '../../domain/models/task_deadline.dart';
import '../../domain/models/task_status.dart';
import '../../domain/repositories/i_task_repository.dart';
import '../datasources/i_task_data_source.dart';

class TaskRepository with UiLoggy implements ITaskRepository {
  /// [clock] da el instante de cierre (`finished_at`); solo se cambia en
  /// pruebas.
  TaskRepository(this._source, {this.clock = systemClock});

  final ITaskDataSource _source;
  final Clock clock;

  /// Lo que hay que escribir en `finished_at` cuando una tarea pasa de
  /// [before] a [after]: el instante actual al terminarse, nulo al reabrirse y
  /// nada si no cambió terminada/no terminada (así un guardado que no cambia
  /// el estado no mueve la hora de cierre).
  Map<String, dynamic> _finishedAtFields(TaskStatus before, TaskStatus after) {
    final wasDone = before == TaskStatus.done;
    final isDone = after == TaskStatus.done;
    if (isDone && !wasDone) {
      return {'finished_at': clock().toUtc().toIso8601String()};
    }
    if (wasDone && !isDone) return {'finished_at': null};
    return const {};
  }

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
    DateTime? deadline,
  }) async {
    final row = await _guard(
      () => _source.createTask({
        'project_id': projectId,
        'title': title,
        'description': description,
        'status': TaskStatus.todo.name,
        if (deadline != null) 'deadline': deadline.toUtc().toIso8601String(),
      }),
    );
    await _syncDerived(projectId);
    return _toTask(row);
  }

  @override
  Future<ProjectTask> updateTaskStatus({
    required ProjectTask task,
    required TaskStatus status,
  }) async {
    final finishedAt = _finishedAtFields(task.status, status);
    await _guard(
      () => _source.updateTask(task.id, {
        'status': status.name,
        ...finishedAt,
      }),
    );
    await _syncDerived(
      task.projectId,
      finishedOfAssigneeOf: task.isDone != (status == TaskStatus.done)
          ? task.id
          : null,
    );
    return _withFinishedAt(task.copyWith(status: status), finishedAt);
  }

  /// [task] con `finished_at` al día según lo que se escribió ([written], vacío
  /// si no se tocó).
  ProjectTask _withFinishedAt(ProjectTask task, Map<String, dynamic> written) {
    if (!written.containsKey('finished_at')) return task;
    final value = written['finished_at'];
    return value == null
        ? task.copyWith(clearFinishedAt: true)
        : task.copyWith(finishedAt: DateTime.parse(value as String));
  }

  @override
  Future<ProjectTask> updateTaskDeadline({
    required ProjectTask task,
    required DateTime? deadline,
    required String userId,
  }) async {
    final rows = await _guard(() => _source.readTasks(task.projectId));
    final current = rows.map(_toTask).where((t) => t.id == task.id).firstOrNull;
    if (current == null) {
      throw const ProjectFailure('La tarea ya no existe.');
    }
    if (current.isDone) {
      throw const ProjectFailure(
        'La tarea ya está terminada: su fecha límite no se puede cambiar.',
      );
    }
    final next = deadline?.toUtc();
    if (next == current.deadline) return current;
    await _guard(
      () => _source.updateTask(task.id, {'deadline': next?.toIso8601String()}),
    );
    final updated = next == null
        ? current.copyWith(clearDeadline: true)
        : current.copyWith(deadline: next);
    // El aviso en el hilo de comentarios es parte del cambio (Q-04), pero ya
    // está hecho: si el aviso falla no se deshace la fecha.
    try {
      await addComment(
        task: updated,
        userId: userId,
        body: TaskDeadline.changeNote(before: current.deadline, after: next),
      );
    } on ProjectFailure catch (e) {
      loggy.warning('No se pudo avisar el cambio de fecha límite: ${e.message}');
    }
    return updated;
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
    // que el progreso del proyecto sigue igual. Sí es una tarea más tomada,
    // salvo que ya fuera suya (p. ej. la devolvió a pendiente y la retoma).
    if (current.assigneeId != userId) {
      await _countTaken(task.projectId, userId, 1);
    }
    return current.copyWith(status: TaskStatus.doing, assigneeId: userId);
  }

  @override
  Future<ProjectTask> saveTaskProgress({
    required ProjectTask task,
    required String description,
    required List<Subtask> subtasks,
  }) async {
    final status = ProjectTask.statusAfterSaving(task.status, subtasks);
    final finishedAt = _finishedAtFields(task.status, status);
    await _guard(
      () => _source.updateTask(task.id, {
        'description': description,
        'checklist': [for (final s in subtasks) s.toJson()],
        'status': status.name,
        ...finishedAt,
      }),
    );
    // Solo si cambió terminada/no terminada se mueve el progreso del proyecto.
    if (status.name != task.status.name &&
        (status == TaskStatus.done || task.status == TaskStatus.done)) {
      await _syncDerived(task.projectId, finishedOfAssigneeOf: task.id);
    }
    return _withFinishedAt(
      task.copyWith(
        description: description,
        subtasks: List.unmodifiable(subtasks),
        status: status,
      ),
      finishedAt,
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
        'createdAt': clock().toUtc().toIso8601String(),
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
    // `tasks_taken` no baja: lo que soltó sigue contando como tomado (y sin
    // terminar) en su estancia.
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
    final assignee = task.assigneeId;
    // Una tarea que ya no existe tampoco cuenta como tomada.
    if (assignee != null) await _countTaken(task.projectId, assignee, -1);
    await _syncDerived(task.projectId, finishedOf: assignee);
  }

  @override
  Future<double> recalculateProgress(String projectId) async {
    final tasks = await getTasks(projectId);
    return _writeProjectStats(projectId, tasks);
  }

  Future<double> _writeProjectStats(
    String projectId,
    List<ProjectTask> tasks,
  ) async {
    final progress = ProjectTask.progressOf(tasks);
    await _guard(
      () => _source.writeProjectTaskStats(
        projectId,
        progress: progress,
        totalTasks: tasks.length,
      ),
    );
    return progress;
  }

  /// Los derivados de una tarea que sí se guardó: el progreso y total de
  /// tareas del proyecto y las terminadas de quien corresponda: [finishedOf]
  /// si ya se sabe quién, o el responsable que tenga ahora la tarea
  /// [finishedOfAssigneeOf] (se lee de la base, no de la copia que tenga quien
  /// llama, que puede estar vieja). Si algo no se pudo actualizar, la tarea no se deshace: se avisa en el
  /// log y el siguiente cambio lo deja bien (se cuenta siempre desde cero).
  Future<void> _syncDerived(
    String projectId, {
    String? finishedOf,
    String? finishedOfAssigneeOf,
  }) async {
    List<ProjectTask> tasks;
    try {
      tasks = await getTasks(projectId);
      await _writeProjectStats(projectId, tasks);
    } catch (e) {
      loggy.warning('No se pudo actualizar el progreso de $projectId: $e');
      return;
    }
    final person =
        finishedOf ??
        tasks
            .where((t) => t.id == finishedOfAssigneeOf)
            .firstOrNull
            ?.assigneeId;
    if (person == null) return;
    try {
      await _syncFinished(projectId, person, tasks);
    } catch (e) {
      loggy.warning(
        'No se pudieron actualizar las terminadas de $person '
        'en $projectId: $e',
      );
    }
  }

  /// `tasks_finished` de [userId]: lo terminado a su nombre en todo el
  /// proyecto, menos lo que ya anotaron sus otras estancias.
  Future<void> _syncFinished(
    String projectId,
    String userId,
    List<ProjectTask> tasks,
  ) async {
    final stays = await _readStays(projectId, userId);
    final current = MemberStay.current(stays);
    if (current == null) return;
    final total = tasks.where((t) => t.assigneeId == userId && t.isDone).length;
    final finished = MemberStay.finishedFor(current, stays, total);
    if (finished == current.finished) return;
    await _guard(
      () => _source.writeMemberCounters(current.id, finished: finished),
    );
  }

  /// Mueve `tasks_taken` de [userId] en su estancia actual, sin bajar de 0.
  /// Es incremental (no se puede contar desde cero: las tareas soltadas ya no
  /// tienen responsable). Es un derivado: si falla, la tarea no se deshace.
  Future<void> _countTaken(String projectId, String userId, int delta) async {
    try {
      final stays = await _readStays(projectId, userId);
      final current = MemberStay.current(stays);
      if (current == null) return;
      final taken = current.taken + delta;
      await _guard(
        () => _source.writeMemberCounters(
          current.id,
          taken: taken < 0 ? 0 : taken,
        ),
      );
    } catch (e) {
      loggy.warning('No se pudieron actualizar las tomadas de $userId: $e');
    }
  }

  Future<List<MemberStay>> _readStays(String projectId, String userId) async {
    final rows = await _guard(() => _source.readMemberStays(projectId, userId));
    return rows.map(_toStay).where((s) => s.id.isNotEmpty).toList();
  }

  MemberStay _toStay(Map<String, dynamic> row) => MemberStay(
    id: (row['_id'] ?? row['id'])?.toString() ?? '',
    isActive: (row['status']?.toString() ?? 'active') == 'active',
    joinedAt: DateTime.tryParse(row['joinedAt']?.toString() ?? ''),
    taken: _count(row['tasks_taken']),
    finished: _count(row['tasks_finished']),
  );

  int _count(Object? value) => value is num ? value.toInt() : 0;

  ProjectTask _toTask(Map<String, dynamic> row) => ProjectTask(
    id: (row['_id'] ?? row['id'])?.toString() ?? '',
    projectId: row['project_id']?.toString() ?? '',
    title: (row['title'] ?? '').toString(),
    description: (row['description'] ?? '').toString(),
    status: TaskStatus.fromName(row['status']?.toString()),
    assigneeId: _nonEmpty(row['assignee_id']),
    subtasks: _decodeChecklist(row['checklist']),
    deadline: _instant(row['deadline']),
    finishedAt: _instant(row['finished_at']),
    creatorId: _nonEmpty(row['_owner']),
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

  /// `timestamptz` llega como texto ISO; lo ilegible o vacío es "sin fecha".
  DateTime? _instant(Object? value) {
    final text = value?.toString().trim() ?? '';
    return DateTime.tryParse(text)?.toUtc();
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
