abstract class IProjectDataSource {
  Future<List<Map<String, dynamic>>> readProjects();
  Future<List<Map<String, dynamic>>> readProjectsByOwner(String ownerId);
  Future<Map<String, dynamic>?> readProjectById(String id);
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData);
  Future<void> updateProject(String id, Map<String, dynamic> changes);
}


