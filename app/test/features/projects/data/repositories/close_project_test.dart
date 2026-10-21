import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/invitations_controller.dart';

void main() {
  late DummyData data;
  late InMemoryProjectDataSource source;
  late ProjectRepository repo;
  late String projectId;

  setUp(() async {
    Get.reset();
    data = DummyData();
    source = InMemoryProjectDataSource(data.projects);
    repo = ProjectRepository(source);
    Get.put<IProjectRepository>(repo);
    final project = await repo.createProject(
      title: 'Proyecto',
      description: 'd',
      jobs: const [],
      skills: const [],
    );
    projectId = project.id;
  });

  tearDown(Get.reset);

  Map<String, dynamic> row() =>
      data.projects.firstWhere((r) => r['_id'] == projectId);

  group('closeProject', () {
    test('marca el proyecto cerrado y lo devuelve leído de vuelta', () async {
      final closed = await repo.closeProject(projectId);

      expect(closed.isOpen, isFalse);
      expect(closed.status, 'closed');
      expect(row()['status'], 'closed');
      // Lo demás queda como estaba.
      expect(closed.title, 'Proyecto');
    });

    test('es idempotente', () async {
      await repo.closeProject(projectId);
      final again = await repo.closeProject(projectId);
      expect(again.isOpen, isFalse);
    });
  });

  group('un proyecto cerrado ya no recibe solicitudes', () {
    test('no se puede postular, y no se escribe la solicitud', () async {
      await repo.closeProject(projectId);

      await expectLater(
        repo.createJoinRequest(projectId: projectId, userId: 'ana'),
        throwsA(
          isA<ProjectFailure>().having(
            (e) => e.message,
            'message',
            contains('cerrado'),
          ),
        ),
      );
      expect(await repo.getJoinRequestsForProject(projectId), isEmpty);
    });

    test('abierto sí recibe solicitudes', () async {
      final request = await repo.createJoinRequest(
        projectId: projectId,
        userId: 'ana',
      );
      expect(request.projectId, projectId);
    });

    test('una solicitud pendiente de antes de cerrar ya no se acepta, '
        'pero sí se puede rechazar', () async {
      final request = await repo.createJoinRequest(
        projectId: projectId,
        userId: 'ana',
      );
      await repo.closeProject(projectId);

      await expectLater(
        repo.acceptJoinRequest(
          requestId: request.id,
          projectId: projectId,
          applicantId: 'ana',
          reviewerId: 'jefe',
        ),
        throwsA(isA<ProjectFailure>()),
      );
      expect(await repo.getMemberProjectIds('ana'), isEmpty);

      await repo.rejectJoinRequest(requestId: request.id, reviewerId: 'jefe');
      final after = await repo.getJoinRequestsForProject(projectId);
      expect(after.single.statusState, 'rejected');
    });
  });

  group('un proyecto cerrado ya no recibe invitaciones', () {
    Future<void> invite(String userId) => source.createInvitations([
      {
        'project_id': projectId,
        'email': '$userId@correo.com',
        'user_id': userId,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      },
    ]);

    test('no se puede aceptar una invitación pendiente', () async {
      await invite('ana');
      final invitation = (await repo.getPendingInvitations('ana')).single;
      await repo.closeProject(projectId);

      await expectLater(
        repo.acceptInvitation(invitation),
        throwsA(
          isA<ProjectFailure>().having(
            (e) => e.message,
            'message',
            contains('cerrado'),
          ),
        ),
      );
      expect(await repo.getMemberProjectIds('ana'), isEmpty);
    });

    test('la lista de invitaciones ya no muestra proyectos cerrados', () async {
      await invite('ana');
      final controller = InvitationsController(
        repository: repo,
        currentUserId: () => 'ana',
        onAccepted: (_) {},
      );
      await controller.fetch();
      expect(controller.invitations, hasLength(1));

      await repo.closeProject(projectId);
      controller.projects.clear(); // sin caché del proyecto abierto
      await controller.fetch();

      expect(controller.invitations, isEmpty);
    });
  });
}
