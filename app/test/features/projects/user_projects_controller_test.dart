import 'dart:async';

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

/// Deja en espera la lectura de solicitudes hasta que la prueba lo decida.
class _GatedSource extends InMemoryProjectDataSource {
  Completer<void>? gate;

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(
    String userId,
  ) async {
    await gate?.future;
    return super.readJoinRequestsByUser(userId);
  }
}

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

  group('listas de Otros proyectos', () {
    test('un guardado que ya es activo no sale en Guardados', () {
      controller.savedProjects.addAll([_project('a'), _project('b')]);
      controller.activeProjects.add(_project('a'));

      expect(controller.unappliedSavedProjects.map((p) => p.id), ['b']);
    });

    test('pendiente y activo a la vez: gana Activos y no queda pendiente', () {
      controller.savedProjects.add(_project('a'));
      controller.appliedProjectIds.add('a');
      controller.activeProjects.add(_project('a'));

      expect(controller.pendingProjects, isEmpty);
      expect(controller.unappliedSavedProjects, isEmpty);
    });

    test('addActiveProject quita la postulación pendiente a ese proyecto', () {
      controller.appliedProjectIds.add('a');

      controller.addActiveProject(_project('a'));

      expect(controller.appliedProjectIds, isNot(contains('a')));
      expect(controller.activeProjects.map((p) => p.id), ['a']);
    });

    test('clear vacía todo lo de la sesión', () {
      controller.coCreatedProjects.add(_project('mio'));
      controller.savedProjects.add(_project('g'));
      controller.activeProjects.add(_project('a'));
      controller.appliedProjectIds.add('p');
      controller.userCreatedProjectIds.add('mio');
      controller.selectedMainTab.value = 1;
      controller.otherProjectsCategoryIndex.value = 3;

      controller.clear();

      expect(controller.coCreatedProjects, isEmpty);
      expect(controller.savedProjects, isEmpty);
      expect(controller.activeProjects, isEmpty);
      expect(controller.appliedProjectIds, isEmpty);
      expect(controller.userCreatedProjectIds, isEmpty);
      expect(controller.selectedMainTab.value, 0);
      expect(controller.otherProjectsCategoryIndex.value, 0);
    });
  });

  group('cargas que cruzan un cambio de sesión', () {
    late _GatedSource source;
    late String projectId;
    var user = 'A';

    setUp(() async {
      Get.reset();
      user = 'A';
      source = _GatedSource();
      repository = ProjectRepository(source);
      Get.put<IProjectRepository>(repository);
      controller = UserProjectsController(currentUserId: () => user);
      final project = await repository.createProject(
        title: 'P',
        description: 'd',
        jobs: const [],
        skills: const [],
      );
      projectId = project.id;
      // Solicitud aceptada (historia) y la membresía que de verdad cuenta.
      await repository.createJoinRequest(
        projectId: projectId,
        userId: 'A',
        status: 'accepted',
      );
      await repository.addProjectMember(
        projectId: projectId,
        userId: 'A',
        role: {'name': 'member'},
      );
    });

    test(
      'sin cambio de sesión el proyecto aceptado entra en Activos',
      () async {
        await controller.fetchUserApplications();

        expect(controller.activeProjects.map((p) => p.id), [projectId]);
      },
    );

    test(
      'si la sesión cambia mientras carga, se descarta el resultado',
      () async {
        source.gate = Completer<void>();
        final loading = controller.fetchUserApplications();

        user = 'B';
        controller.clear();
        source.gate!.complete();
        await loading;

        expect(controller.activeProjects, isEmpty);
        expect(controller.appliedProjectIds, isEmpty);
      },
    );
  });
}
