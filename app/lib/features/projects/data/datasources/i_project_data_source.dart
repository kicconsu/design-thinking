abstract class IProjectDataSource {
  Future<List<Map<String, dynamic>>> readProjects();
  Future<List<Map<String, dynamic>>> readProjectsByOwner(String ownerId);
  Future<Map<String, dynamic>?> readProjectById(String id);
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData);
  Future<Map<String, dynamic>> createJoinRequest(Map<String, dynamic> joinRequestData);
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(String userId);
  Future<List<Map<String, dynamic>>> readJoinRequestsForProject(String projectId);
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
}



