import '../models/project.dart';

abstract class IProjectRepository {
  Future<List<Project>> getProjects();
  Future<Project?> getProjectById(String id);
}
