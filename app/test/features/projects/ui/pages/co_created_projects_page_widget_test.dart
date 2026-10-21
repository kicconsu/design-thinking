import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/co_created_projects_page.dart';
import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

import '../../../../support/builders.dart';

void main() {
  late UserProjectsController projects;

  Future<void> pumpPage(WidgetTester tester) async {
    Get.reset();
    final repo = ProjectRepository(InMemoryProjectDataSource());
    Get.put<IProjectRepository>(repo);
    projects = Get.put(UserProjectsController(currentUserId: () => 'yo'));
    Get.put(CollaborationRequestsController(repository: repo));
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: CoCreatedProjectsPage())),
    );
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);
  group('CoCreatedProjectsPage', () {
    testWidgets('sin proyectos propios lo dice y ofrece crear el primero', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Aún no tienes proyectos propios.'), findsOneWidget);
      expect(find.text('Crear mi primer proyecto'), findsOneWidget);
    });

    testWidgets('«Crear mi primer proyecto» abre el formulario', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.text('Crear mi primer proyecto'));
      await tester.pumpAndSettle();

      expect(find.text('Crear Proyecto'), findsOneWidget);
      expect(find.text('Nombre del proyecto'), findsOneWidget);
    });

    testWidgets('mientras carga y no hay nada, muestra una espera', (
      tester,
    ) async {
      await pumpPage(tester);

      projects.isLoadingProjects.value = true;
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Aún no tienes proyectos propios.'), findsNothing);
    });

    testWidgets('con proyectos los lista y ofrece «Nuevo»', (tester) async {
      await pumpPage(tester);

      projects.coCreatedProjects.addAll([
        aProject(id: 'a', owner: 'yo'),
        aProject(id: 'b', owner: 'yo'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Proyecto a'), findsOneWidget);
      expect(find.text('Proyecto b'), findsOneWidget);
      expect(find.text('Nuevo'), findsOneWidget);
      expect(find.text('Aún no tienes proyectos propios.'), findsNothing);
    });

    testWidgets('cada proyecto muestra cuántas solicitudes tiene', (
      tester,
    ) async {
      await pumpPage(tester);

      projects.coCreatedProjects.add(aProject(id: 'a', owner: 'yo'));
      await tester.pumpAndSettle();

      expect(find.text('0 solicitudes'), findsOneWidget);
    });

    testWidgets('«Nuevo» abre el formulario de creación', (tester) async {
      await pumpPage(tester);
      projects.coCreatedProjects.add(aProject(id: 'a', owner: 'yo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();

      expect(find.text('Crear Proyecto'), findsOneWidget);
    });
  });
}
