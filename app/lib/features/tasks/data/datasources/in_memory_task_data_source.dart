import 'i_task_data_source.dart';

/// Fuente en memoria: modo mock (sin contrato) y pruebas.
class InMemoryTaskDataSource implements ITaskDataSource {
  final List<Map<String, dynamic>> _tasks = [];
  final Map<String, double> progressByProject = {};
  final List<Map<String, dynamic>> _contributions = [];
  int _seq = 0;

  @override
  Future<List<Map<String, dynamic>>> readTasks(String projectId) async => [
    for (final t in _tasks)
      if (t['project_id'] == projectId) Map<String, dynamic>.from(t),
  ];

  @override
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    final row = {...taskData, '_id': 'local-task-${++_seq}'};
    _tasks.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> fields,
  ) async {
    final i = _tasks.indexWhere((t) => t['_id'] == taskId);
    if (i == -1) throw StateError('Tarea $taskId no existe');
    _tasks[i] = {..._tasks[i], ...fields};
    return Map<String, dynamic>.from(_tasks[i]);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t['_id'] == taskId);
  }

  @override
  Future<List<Map<String, dynamic>>> readContributions(String taskId) async => [
    for (final c in _contributions)
      if (c['task_id'] == taskId) Map<String, dynamic>.from(c),
  ];

  @override
  Future<Map<String, dynamic>> createContribution(
    Map<String, dynamic> contributionData,
  ) async {
    final row = {...contributionData, '_id': 'local-contribution-${++_seq}'};
    _contributions.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> writeProjectProgress(String projectId, double progress) async {
    progressByProject[projectId] = progress;
  }
}
