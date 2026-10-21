import 'package:imker/features/tasks/data/datasources/i_task_data_source.dart';

import 'fake_project_data_source.dart';

/// Datasource de tareas para pruebas de integración: tareas, comentarios y
/// contadores de miembros en memoria, sin red.
///
/// Si recibe el [FakeProjectDataSource], `writeProjectTaskStats` también deja
/// `progress` y `total_tasks` en la fila del proyecto, que es lo que haría
/// Roble y de donde lee la pestaña «Progreso».
class FakeTaskDataSource implements ITaskDataSource {
  FakeTaskDataSource({
    required this.currentUserId,
    this.projects,
    List<Map<String, dynamic>> tasks = const [],
    List<Map<String, dynamic>> members = const [],
  }) : tasks = [for (final t in tasks) Map<String, dynamic>.of(t)],
       members = [for (final m in members) Map<String, dynamic>.of(m)];

  /// Quién figura como creador (`_owner`) de lo que se crea.
  final String currentUserId;
  final FakeProjectDataSource? projects;

  final List<Map<String, dynamic>> tasks;

  /// Filas de `project_member` con sus contadores `tasks_taken` y
  /// `tasks_finished`.
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> contributions = [];
  final Map<String, double> progressByProject = {};
  final Map<String, int> totalTasksByProject = {};

  int _seq = 0;

  /// La tarea [taskId], o null.
  Map<String, dynamic>? taskRow(String taskId) =>
      tasks.where((t) => t['_id'] == taskId).firstOrNull;

  /// La primera tarea de [projectId] con ese título, o null.
  Map<String, dynamic>? taskByTitle(String projectId, String title) => tasks
      .where((t) => t['project_id'] == projectId && t['title'] == title)
      .firstOrNull;

  /// La estancia de [userId] en [projectId], o null.
  Map<String, dynamic>? memberRow(String projectId, String userId) => members
      .where((m) => m['project_id'] == projectId && m['user_id'] == userId)
      .firstOrNull;

  @override
  Future<List<Map<String, dynamic>>> readTasks(String projectId) async => [
    for (final t in tasks)
      if (t['project_id'] == projectId) Map<String, dynamic>.of(t),
  ];

  @override
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    final row = <String, dynamic>{
      ...taskData,
      '_id': 'tarea-nueva-${++_seq}',
      '_owner': currentUserId,
    };
    tasks.add(row);
    return Map.of(row);
  }

  @override
  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> fields,
  ) async {
    final i = tasks.indexWhere((t) => t['_id'] == taskId);
    if (i == -1) throw StateError('Tarea $taskId no existe');
    tasks[i] = {...tasks[i], ...fields};
    return Map.of(tasks[i]);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    tasks.removeWhere((t) => t['_id'] == taskId);
  }

  @override
  Future<List<Map<String, dynamic>>> readContributions(String taskId) async => [
    for (final c in contributions)
      if (c['task_id'] == taskId) Map<String, dynamic>.of(c),
  ];

  @override
  Future<Map<String, dynamic>> createContribution(
    Map<String, dynamic> contributionData,
  ) async {
    final row = <String, dynamic>{
      ...contributionData,
      '_id': 'comentario-${++_seq}',
    };
    contributions.add(row);
    return Map.of(row);
  }

  @override
  Future<void> writeProjectTaskStats(
    String projectId, {
    required double progress,
    required int totalTasks,
  }) async {
    progressByProject[projectId] = progress;
    totalTasksByProject[projectId] = totalTasks;
    projects?.patchProject(projectId, {
      'progress': progress,
      'total_tasks': totalTasks,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> readMemberStays(
    String projectId,
    String userId,
  ) async => [
    for (final m in members)
      if (m['project_id'] == projectId && m['user_id'] == userId)
        Map<String, dynamic>.of(m),
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
