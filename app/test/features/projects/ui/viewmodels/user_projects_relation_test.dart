import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project_relation.dart';
import 'package:imker/features/projects/ui/viewmodels/invitations_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

import '../../../../support/builders.dart';

void main() {
  tearDown(Get.reset);

  group('relationOf', () {
    late UserProjectsController controller;
    final project = aProject(id: 'p', title: 'P');

    setUp(() {
      Get.reset();
      controller = UserProjectsController(currentUserId: () => 'u1');
    });

    test('sin nada: none', () {
      expect(controller.relationOf(project), ProjectRelation.none);
    });

    test('solo guardado: saved', () {
      controller.savedProjects.add(project);
      expect(controller.relationOf(project), ProjectRelation.saved);
    });

    test('guardado y postulado: pending', () {
      controller.savedProjects.add(project);
      controller.appliedProjectIds.add('p');
      expect(controller.relationOf(project), ProjectRelation.pending);
    });

    test('guardado, postulado e invitado: invited gana', () async {
      final invitations = Get.put(
        InvitationsController(
          repository: ProjectRepository(
            InMemoryProjectDataSource(DummyData().projects),
          ),
          currentUserId: () => 'u1',
        ),
      );
      final inMemory = InMemoryProjectDataSource(DummyData().projects);
      await inMemory.createInvitations([
        {
          'project_id': 'p',
          'email': 'a@b.co',
          'user_id': 'u1',
          'status': 'pending',
        },
      ]);
      invitations.invitations.add(
        (await ProjectRepository(inMemory).getPendingInvitations('u1')).single,
      );
      controller.savedProjects.add(project);
      controller.appliedProjectIds.add('p');

      expect(controller.relationOf(project), ProjectRelation.invited);
    });

    test('con todo lo anterior y además activo: active gana', () {
      controller.savedProjects.add(project);
      controller.appliedProjectIds.add('p');
      controller.activeProjects.add(project);
      expect(controller.relationOf(project), ProjectRelation.active);
    });

    test('creador: owner gana a todo', () {
      controller.userCreatedProjectIds.add('p');
      controller.activeProjects.add(project);
      expect(controller.relationOf(project), ProjectRelation.owner);
    });
  });
}
