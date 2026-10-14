abstract class ITaskDataSource {
  Future<List<Map<String, dynamic>>> readTasks(String projectId);

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData);

  /// Escribe sólo las columnas de [fields] en la tarea [taskId].
  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> fields,
  );

  Future<void> deleteTask(String taskId);

  /// Escribe `project.progress` (porcentaje 0–100).
  Future<void> writeProjectProgress(String projectId, double progress);
}
