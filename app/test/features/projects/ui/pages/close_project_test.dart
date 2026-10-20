import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/project_detail_page.dart';
import 'package:imker/features/projects/ui/pages/project_info_page.dart';
import 'package:imker/features/projects/ui/viewmodels/invitations_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/project_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

void main() {
  late DummyData data;
  late InMemoryProjectDataSource source;
  late ProjectRepository repo;
  late String projectId;

  setUp(() async {
    Get.reset();
    data = DummyData();
    source = InMemoryProjectDataSource(data);
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

  group('ProjectInfoController.closeProject', () {
    test(
      'cierra, actualiza la vista y las listas; repetir no hace nada',
      () async {
        final list = UserProjectsController();
        Get.put(list);
        final project = await repo.getProjectById(projectId);
        list.coCreatedProjects.add(project!);
        final info = ProjectInfoController(project);

        expect(await info.closeProject(), isNull);

        expect(info.project.value.isOpen, isFalse);
        expect(list.coCreatedProjects.single.isOpen, isFalse);
        expect(info.isClosing.value, isFalse);
        expect(await info.closeProject(), isNull);
      },
    );
  });

  group('vistas', () {
    Future<void> openInfo(WidgetTester tester, {required String user}) async {
      // Al abrir se relee el proyecto: el dueño tiene que estar en la fila.
      row()['_owner'] = 'jefe';
      final project = (await repo.getProjectById(projectId))!
          .copyWith(owner: 'jefe');
      await tester.pumpWidget(
        GetMaterialApp(
          home: ProjectInfoPage(project: project, currentUserId: () => user),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('el creador cierra el proyecto desde el menú y ve el aviso', (
      tester,
    ) async {
      Get.put(UserProjectsController());
      await openInfo(tester, user: 'jefe');
      expect(find.textContaining('Proyecto cerrado'), findsNothing);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar proyecto'));
      await tester.pumpAndSettle();

      // Pide confirmación y todavía no cierra.
      expect(
        find.textContaining('dejará de recibir solicitudes'),
        findsOneWidget,
      );
      expect(row()['status'], isNot('closed'));

      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar proyecto'));
      await tester.pumpAndSettle();

      expect(row()['status'], 'closed');
      expect(find.textContaining('Proyecto cerrado'), findsOneWidget);
      // Cerrado ya no hay nada que ofrecer en el menú.
      expect(find.byType(PopupMenuButton<String>), findsNothing);

      // El aviso deja un temporizador de 3 s.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('cancelar en la confirmación no cierra nada', (tester) async {
      Get.put(UserProjectsController());
      await openInfo(tester, user: 'jefe');

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar proyecto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(row()['status'], isNot('closed'));
      expect(find.textContaining('Proyecto cerrado'), findsNothing);
    });

    testWidgets('quien no es el creador no ve «Cerrar proyecto»', (
      tester,
    ) async {
      Get.put(UserProjectsController());
      await openInfo(tester, user: 'ana');

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Cerrar proyecto'), findsNothing);
      expect(find.text('Salir del proyecto'), findsOneWidget);
    });

    testWidgets(
      'un proyecto cerrado muestra el aviso a todos, creador incluido',
      (tester) async {
        Get.put(UserProjectsController());
        await repo.closeProject(projectId);
        await openInfo(tester, user: 'jefe');
        // La lectura fresca al abrir deja el proyecto como cerrado.
        expect(find.textContaining('Proyecto cerrado'), findsOneWidget);
        expect(find.byType(PopupMenuButton<String>), findsNothing);
      },
    );

    testWidgets('la ficha de postulación no ofrece postular a un cerrado', (
      tester,
    ) async {
      Get.put(UserProjectsController());
      final closed = (await repo.closeProject(projectId));

      await tester.pumpWidget(
        GetMaterialApp(home: ProjectDetailPage(project: closed)),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Quiero colaborar!'), findsNothing);
      expect(find.textContaining('Proyecto cerrado'), findsOneWidget);
    });
  });
}
