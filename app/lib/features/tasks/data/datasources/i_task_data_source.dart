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

  /// Escribe `project.progress` (porcentaje 0–100) y `project.total_tasks`.
  Future<void> writeProjectTaskStats(
    String projectId, {
    required double progress,
    required int totalTasks,
  });

  /// Filas de `project_member` de [userId] en [projectId]: una por estancia,
  /// activas o no.
  Future<List<Map<String, dynamic>>> readMemberStays(
    String projectId,
    String userId,
  );

  /// Escribe `tasks_taken` y/o `tasks_finished` en la fila [memberRowId] de
  /// `project_member`. Lo que llega null no se toca.
  Future<void> writeMemberCounters(
    String memberRowId, {
    int? taken,
    int? finished,
  });
}
