abstract class ITrustDataSource {
  /// Una fila por (persona, proyecto) de cada una de [userIds]: `user_id`,
  /// `project_id`, `tasks_finished`, `tasks_taken`, `total_tasks`, `progress`.
  /// Los contadores suman todas las estancias de la persona en el proyecto.
  Future<List<Map<String, dynamic>>> readParticipations(List<String> userIds);

  /// Una fila por persona con tareas terminadas: `user_id`, `con_deadline`,
  /// `a_tiempo`.
  Future<List<Map<String, dynamic>>> readDeliveries(List<String> userIds);
}
