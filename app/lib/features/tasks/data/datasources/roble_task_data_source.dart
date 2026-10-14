import 'dart:convert';

import 'package:loggy/loggy.dart';

import 'package:imker/core/roble/roble_client.dart';

import 'i_task_data_source.dart';

class RobleTaskDataSource with UiLoggy implements ITaskDataSource {
  RobleTaskDataSource(this._client);

  final RobleClient _client;

  @override
  Future<List<Map<String, dynamic>>> readTasks(String projectId) =>
      _client.db.read(RobleClient.tasks, filters: {'project_id': projectId});

  @override
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) {
    loggy.debug('createTask payload: $taskData');
    return _client.db.create(RobleClient.tasks, taskData);
  }

  @override
  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> fields,
  ) async {
    // Roble rechaza una List nativa en una columna jsonb: el checklist viaja
    // como texto JSON, igual que `jobs` y `skills` de los proyectos.
    final payload = Map<String, dynamic>.from(fields);
    if (payload['checklist'] is List) {
      payload['checklist'] = jsonEncode(payload['checklist']);
    }
    loggy.debug('updateTask id=$taskId fields: $payload');
    await _client.db.update(RobleClient.tasks, taskId, payload);
    return {'_id': taskId, ...fields};
  }

  @override
  Future<List<Map<String, dynamic>>> readContributions(String taskId) =>
      _client.db.read(RobleClient.contributions, filters: {'task_id': taskId});

  @override
  Future<Map<String, dynamic>> createContribution(
    Map<String, dynamic> contributionData,
  ) {
    loggy.debug('createContribution payload: $contributionData');
    return _client.db.create(RobleClient.contributions, contributionData);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _client.db.delete(RobleClient.tasks, taskId);
  }

  @override
  Future<void> writeProjectProgress(String projectId, double progress) async {
    await _client.db.update(RobleClient.projects, projectId, {
      'progress': progress,
    });
  }
}
