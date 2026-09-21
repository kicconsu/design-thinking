abstract class IProjectDataSource {
  Future<List<Map<String, dynamic>>> readProjects();
  Future<Map<String, dynamic>?> readProjectById(String id);
}
