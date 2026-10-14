import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'package:imker/features/projects/domain/project_failure.dart';

import '../../domain/models/project_task.dart';
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
  );

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
