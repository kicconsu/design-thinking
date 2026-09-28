import '../models/project.dart';
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
}
