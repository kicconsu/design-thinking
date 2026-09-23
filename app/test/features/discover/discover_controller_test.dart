import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';

class _MockFailingRepository implements IProjectRepository {
  @override
  Future<List<Project>> getProjects() async {
    throw const ProjectFailure('Error de prueba');
  }

  @override
  Future<List<Project>> getProjectsByOwner(String ownerId) async {
    throw const ProjectFailure('Error de prueba');
  }

  @override
  Future<Project?> getProjectById(String id) async => null;


  @override
  Future<Project> createProject({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
    String imageUrl = '',
  }) async {
    throw const ProjectFailure('Error de prueba');
  }
}


void main() {
  group('DiscoverController', () {
    test('carga proyectos exitosamente en onInit', () async {
      final repo = ProjectRepository(InMemoryProjectDataSource());
      final controller = DiscoverController(repo);

      await controller.loadProjects();

      expect(controller.isLoading.value, isFalse);
      expect(controller.error.value, isNull);
      expect(controller.projects, isNotEmpty);
      expect(controller.projects.length, 3);
    });

    test('captura ProjectFailure y asigna mensaje al estado de error', () async {
      final controller = DiscoverController(_MockFailingRepository());

      await controller.loadProjects();

      expect(controller.isLoading.value, isFalse);
      expect(controller.error.value, 'Error de prueba');
      expect(controller.projects, isEmpty);
    });
  });
}
