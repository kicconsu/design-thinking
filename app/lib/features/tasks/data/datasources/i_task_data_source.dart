abstract class ITaskDataSource {
  Future<List<Map<String, dynamic>>> readTasks(String projectId);

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData);

  /// Escribe sólo las columnas de [fields] en la tarea [taskId].
  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> fields,
  );

  Future<void> deleteTask(String taskId);

  /// Filas de `contribution` de esa tarea (sus comentarios).
  Future<List<Map<String, dynamic>>> readContributions(String taskId);

  Future<Map<String, dynamic>> createContribution(
    Map<String, dynamic> contributionData,
  );

  /// Escribe `project.progress` (porcentaje 0–100).
  Future<void> writeProjectProgress(String projectId, double progress);
}
