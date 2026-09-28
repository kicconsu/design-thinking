abstract class IProjectDataSource {
  Future<List<Map<String, dynamic>>> readProjects();
  Future<List<Map<String, dynamic>>> readProjectsByOwner(String ownerId);
  Future<Map<String, dynamic>?> readProjectById(String id);
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData);
  Future<Map<String, dynamic>> createJoinRequest(
    Map<String, dynamic> joinRequestData,
  );
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(String userId);
  Future<List<Map<String, dynamic>>> readJoinRequestsForProject(
    String projectId,
  );
  Future<Map<String, dynamic>> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  });
  Future<Map<String, dynamic>?> readUserProfile(String userId);
  Future<Map<String, dynamic>> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  });
  Future<List<Map<String, dynamic>>> readProjectMembers({String? projectId});

  /// Filas de `project_saved` de un usuario (cada una es un proyecto guardado).
  Future<List<Map<String, dynamic>>> readSavedByUser(String userId);

  /// Inserta una fila en `project_saved`. Si ya existe no debe duplicarse.
  Future<Map<String, dynamic>> createSaved({
    required String userId,
    required String projectId,
  });

  /// Borra por `_id` las filas de `project_saved` de ese proyecto para ese
  /// usuario. Roble borra por `_id`, por eso se recorre lo que se leyó.
  Future<void> deleteSaved({required String userId, required String projectId});

  /// Devuelve una fila `{email, user_id}` por cada correo que sí tiene cuenta.
  /// Los que no aparecen en la respuesta no existen.
  Future<List<Map<String, dynamic>>> findUsersByEmails(List<String> emails);

  /// Inserta todas las invitaciones en una sola petición. Devuelve las que
  /// quedaron insertadas: si el servidor rechazó alguna, devuelve menos
  /// filas que las enviadas.
  Future<List<Map<String, dynamic>>> createInvitations(
    List<Map<String, dynamic>> invitations,
  );

  /// Borrado compensatorio de una creación fallida: invitaciones, miembros
  /// y el proyecto. Lo usa el repositorio para deshacerlo todo si alguna
  /// invitación no se pudo enviar.
  Future<void> deleteProjectCascade(String projectId);
}
