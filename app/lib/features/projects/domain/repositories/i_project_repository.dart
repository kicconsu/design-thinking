import '../models/project.dart';

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
  });
}

