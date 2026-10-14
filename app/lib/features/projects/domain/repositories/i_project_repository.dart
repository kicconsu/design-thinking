import '../models/project.dart';
import '../models/project_member.dart';
import '../models/project_invitation.dart';
import '../models/project_join_request.dart';

abstract class IProjectRepository {
  Future<List<Project>> getProjects();
  Future<List<Project>> getProjectsByOwner(String ownerId);
  Future<Project?> getProjectById(String id);

  Future<Project> createProject({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
    String imageUrl = '',
    List<String> inviteEmails = const [],
  });

  /// Correos de [emails] que NO tienen cuenta. Vacío = todos existen.
  /// Se llama antes de crear nada para poder abortar sin efectos parciales.
  Future<List<String>> validateInviteEmails(List<String> emails);

  Future<ProjectJoinRequest> createJoinRequest({
    required String projectId,
    String? userId,
    dynamic status,
  });

  Future<List<ProjectJoinRequest>> getJoinRequestsByUser(String userId);
  Future<List<ProjectJoinRequest>> getJoinRequestsForProject(String projectId);
  Future<ProjectJoinRequest> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  });
  Future<Map<String, dynamic>?> getUserProfile(String userId);
  Future<void> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  });

  /// IDs de los proyectos que ese usuario tiene guardados (`project_saved`).
  Future<List<String>> getSavedProjectIds(String userId);

  /// Guarda un proyecto para el usuario. Idempotente: repetirlo no duplica.
  Future<void> saveProject({required String userId, required String projectId});

  /// Quita el proyecto de guardados del usuario.
  Future<void> unsaveProject({
    required String userId,
    required String projectId,
  });

  /// Invitaciones `pending` dirigidas a ese usuario.
  Future<List<ProjectInvitation>> getPendingInvitations(String userId);

  /// Responde una invitación: `accepted` o `declined`.
  Future<void> respondToInvitation({
    required String invitationId,
    required bool accept,
  });

  /// Quienes están en el proyecto ahora (`status` activo), con su nombre y
  /// carrera del perfil. El creador va primero y luego por fecha de ingreso.
  /// Un perfil que no se pueda leer no tumba la lista: ese miembro sale con un
  /// nombre genérico.
  Future<List<ProjectMember>> getProjectMembers(String projectId);

  /// En qué anda una persona: los proyectos que creó y en los que colabora
  /// hoy (estancia activa), sin repetir y con los creados primero. Los de los
  /// que salió o la sacaron no cuentan.
  Future<List<Project>> getProjectsOfPerson(String userId);

  /// IDs de proyectos donde ese usuario es miembro sin ser su creador.
  Future<List<String>> getMemberProjectIds(String userId);

  /// Cancela las solicitudes `pending` de ese usuario a ese proyecto.
  /// Devuelve cuántas canceló. Se usa cuando ya es miembro por otra vía
  /// (p. ej. aceptó una invitación): la solicitud quedó obsoleta.
  /// [cancelledBy] es quien hace el cambio; por defecto, la propia persona.
  Future<int> cancelPendingJoinRequests({
    required String projectId,
    required String userId,
    String? cancelledBy,
  });

  // ─── Entrar a un proyecto ─────────────────────────────────────────────────
  // Cada operación aplica la regla completa y se puede reintentar: primero la
  // membresía (idempotente), después los estados, y al final una limpieza que
  // no es crítica. Lanzan [ProjectFailure].

  /// El dueño acepta una solicitud: activa al miembro, marca `accepted` y
  /// cierra las demás solicitudes e invitaciones pendientes de esa persona.
  Future<void> acceptJoinRequest({
    required String requestId,
    required String projectId,
    required String applicantId,
    required String reviewerId,
  });

  /// El dueño rechaza una solicitud. No toca la membresía.
  Future<void> rejectJoinRequest({
    required String requestId,
    required String reviewerId,
  });

  /// La persona acepta una invitación: activa su membresía, marca `accepted`
  /// y cancela sus solicitudes pendientes a ese proyecto.
  Future<void> acceptInvitation(ProjectInvitation invitation);

  /// La persona rechaza una invitación. No toca la membresía.
  Future<void> declineInvitation(ProjectInvitation invitation);

  // ─── Salir de un proyecto ─────────────────────────────────────────────────
  // Lo crítico (cerrar la estancia) va primero; la limpieza es opcional y no
  // tumba la operación. Se pueden reintentar: si ya no hay estancia activa
  // cuentan como hechas. Lanzan [ProjectFailure].

  /// [userId] sale del proyecto: su estancia pasa a `left` y se borra su
  /// guardado del proyecto. El creador no puede salir.
  Future<void> leaveProject({
    required String projectId,
    required String userId,
  });

  /// El creador ([requestedBy]) saca a [memberUserId]: su estancia pasa a
  /// `removed`. No se puede sacar al creador ni a uno mismo. Su guardado se
  /// conserva (es una preferencia suya).
  Future<void> removeMember({
    required String projectId,
    required String memberUserId,
    required String requestedBy,
  });

  /// `user_id` de quienes colaboran hoy en el proyecto (sin duplicados).
  Future<List<String>> getActiveMemberUserIds(String projectId);
}
