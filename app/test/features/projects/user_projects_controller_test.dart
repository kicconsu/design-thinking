import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

Project _project(String id) => Project(
  id: id,
  title: 'Proyecto $id',
  imageUrl: 'https://example.com/$id.png',
  description: 'Descripción',
  jobs: const [],
  skills: const [],
);

void main() {
  late UserProjectsController controller;
  late IProjectRepository repository;

  setUp(() {
    Get.reset();
    repository = ProjectRepository(InMemoryProjectDataSource());
    Get.put<IProjectRepository>(repository);
    controller = UserProjectsController();
  });

  tearDown(Get.reset);

  group('toggleSaveProject con postulación pendiente', () {
    test('no desguarda un proyecto aplicado', () async {
      await repository.saveProject(userId: 'demo-user', projectId: 'p1');
      controller.savedProjects.add(_project('p1'));
      controller.appliedProjectIds.add('p1');

      final stillSaved = await controller.toggleSaveProject(_project('p1'));

      expect(stillSaved, isTrue);
      expect(controller.isSaved('p1'), isTrue);
      expect(await repository.getSavedProjectIds('demo-user'), contains('p1'));
      expect(controller.pendingProjects.map((p) => p.id), contains('p1'));
    });

    test('no guarda un proyecto aplicado que faltaba en guardados', () async {
      controller.appliedProjectIds.add('p2');

      final saved = await controller.toggleSaveProject(_project('p2'));

      expect(saved, isFalse);
      expect(controller.isSaved('p2'), isFalse);
      expect(
        await repository.getSavedProjectIds('demo-user'),
        isNot(contains('p2')),
      );
    });
  });

  group('toggleSaveProject sin postulación', () {
    test('alterna guardar y desguardar', () async {
      final saved = await controller.toggleSaveProject(_project('p3'));
      expect(saved, isTrue);
      expect(controller.isSaved('p3'), isTrue);

      final unsaved = await controller.toggleSaveProject(_project('p3'));
      expect(unsaved, isFalse);
      expect(controller.isSaved('p3'), isFalse);
      expect(
        await repository.getSavedProjectIds('demo-user'),
        isNot(contains('p3')),
      );
    });
  });
}
