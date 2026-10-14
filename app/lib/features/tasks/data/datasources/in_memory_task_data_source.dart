import 'i_task_data_source.dart';

/// Fuente en memoria: modo mock (sin contrato) y pruebas.
class InMemoryTaskDataSource implements ITaskDataSource {
  final List<Map<String, dynamic>> _tasks = [];
  final Map<String, double> progressByProject = {};
  final Map<String, int> totalTasksByProject = {};

  /// Filas de `project_member` (con `_id`, `project_id`, `user_id`, `status`,
  /// `joinedAt`, `tasks_taken`, `tasks_finished`). Las pruebas las siembran.
  final List<Map<String, dynamic>> members = [];
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
  Future<void> writeProjectTaskStats(
    String projectId, {
    required double progress,
    required int totalTasks,
  }) async {
    progressByProject[projectId] = progress;
    totalTasksByProject[projectId] = totalTasks;
  }

  @override
  Future<List<Map<String, dynamic>>> readMemberStays(
    String projectId,
    String userId,
  ) async => [
    for (final m in members)
      if (m['project_id'] == projectId && m['user_id'] == userId)
        Map<String, dynamic>.from(m),
  ];

  @override
  Future<void> writeMemberCounters(
    String memberRowId, {
    int? taken,
    int? finished,
  }) async {
    final i = members.indexWhere((m) => m['_id'] == memberRowId);
    if (i == -1) throw StateError('Miembro $memberRowId no existe');
    members[i] = {
      ...members[i],
      'tasks_taken': ?taken,
      'tasks_finished': ?finished,
    };
  }
}
