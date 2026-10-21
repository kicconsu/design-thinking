import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/projects_page.dart';
import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/invitations_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

import '../../../../support/fake_auth_repository.dart';
import '../../../../support/builders.dart';

void main() {
  late FakeAuthRepository repo;
  late UserProjectsController projects;

  Future<void> pumpPage(WidgetTester tester, {bool guest = false}) async {
    Get.reset();
    repo = FakeAuthRepository();
    final auth = Get.put(AuthenticationController(repo));
    await tester.pump();
    if (guest) await auth.signInAsGuest();
    final projectRepo = ProjectRepository(InMemoryProjectDataSource());
    Get.put<IProjectRepository>(projectRepo);
    projects = Get.put(UserProjectsController(currentUserId: () => 'yo'));
    Get.put(CollaborationRequestsController(repository: projectRepo));
    Get.put(
      InvitationsController(repository: projectRepo, currentUserId: () => 'yo'),
    );
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: ProjectsPage())),
    );
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);
  group('ProjectsPage', () {
    testWidgets('un invitado ve la invitación a completar su cuenta', (
      tester,
    ) async {
      await pumpPage(tester, guest: true);

      expect(find.text('Tus proyectos y colaboraciones'), findsOneWidget);
      expect(find.textContaining('Mis proyectos ('), findsNothing);
    });

    testWidgets('con sesión muestra las dos pestañas con su cuenta', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Mis proyectos (0)'), findsOneWidget);
      expect(find.text('Otros proyectos (0)'), findsOneWidget);
    });

    testWidgets('el número de «Mis proyectos» sube con cada proyecto propio', (
      tester,
    ) async {
      await pumpPage(tester);

      projects.coCreatedProjects.addAll([
        aProject(id: 'a', owner: 'yo'),
        aProject(id: 'b', owner: 'yo'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Mis proyectos (2)'), findsOneWidget);
    });

    testWidgets('«Otros proyectos» suma guardados, pendientes y activos', (
      tester,
    ) async {
      await pumpPage(tester);

      projects.savedProjects.addAll([
        aProject(id: 's', owner: 'yo'),
        aProject(id: 'p', owner: 'yo'),
      ]);
      projects.appliedProjectIds.add('p');
      projects.activeProjects.add(aProject(id: 'a', owner: 'yo'));
      await tester.pumpAndSettle();

      expect(find.text('Otros proyectos (3)'), findsOneWidget);
    });

    testWidgets('arranca en «Mis proyectos» y la otra pestaña la cambia', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(projects.selectedMainTab.value, 0);

      await tester.tap(find.text('Otros proyectos (0)'));
      await tester.pumpAndSettle();

      expect(projects.selectedMainTab.value, 1);
      expect(find.text('Guardados'), findsOneWidget);

      await tester.tap(find.text('Mis proyectos (0)'));
      await tester.pumpAndSettle();

      expect(projects.selectedMainTab.value, 0);
    });
  });
}
