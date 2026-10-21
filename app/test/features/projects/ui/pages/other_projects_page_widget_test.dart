import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_invitation.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/ui/pages/other_projects_page.dart';
import 'package:imker/features/projects/ui/viewmodels/invitations_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

import '../../../../support/fake_project_repository.dart';
import '../../../../support/builders.dart';

ProjectInvitation _invitation(
  String id,
  String projectId, {
  String userId = 'yo',
}) => ProjectInvitation(
  id: id,
  projectId: projectId,
  userId: userId,
  email: 'yo@uninorte.edu.co',
  status: 'pending',
);

void main() {
  late FakeProjectRepository repo;
  late UserProjectsController projects;
  late InvitationsController invitations;
  final accepted = <Project>[];

  Future<void> pumpPage(WidgetTester tester) async {
    projects = Get.put(UserProjectsController(currentUserId: () => 'yo'));
    invitations = Get.put(
      InvitationsController(
        repository: repo,
        currentUserId: () => 'yo',
        onAccepted: accepted.add,
      ),
    );
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: OtherProjectsPage())),
    );
    await tester.pumpAndSettle();
  }

  /// Pasa a la sección siguiente con la flecha de la cabecera.
  Future<void> next(WidgetTester tester, String to) async {
    await tester.tap(find.byTooltip('Sección siguiente: $to'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    Get.reset();
    repo = FakeProjectRepository();
    accepted.clear();
  });

  tearDown(Get.reset);

  group('cabecera y secciones', () {
    testWidgets('arranca en «Guardados» y dice que está vacía', (tester) async {
      await pumpPage(tester);

      expect(find.text('Guardados'), findsOneWidget);
      expect(find.text('0 proyectos'), findsOneWidget);
      expect(
        find.textContaining('No tienes proyectos guardados sin postular'),
        findsOneWidget,
      );
      // Es la primera sección: no hay flecha hacia atrás.
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('las flechas recorren las cuatro secciones', (tester) async {
      await pumpPage(tester);

      await next(tester, 'Pendientes');
      expect(find.text('Pendientes'), findsOneWidget);
      expect(
        find.textContaining('No tienes postulaciones pendientes'),
        findsOneWidget,
      );

      await next(tester, 'Activos');
      expect(find.text('Activos'), findsOneWidget);
      expect(
        find.textContaining('Aún no tienes colaboraciones activas'),
        findsOneWidget,
      );

      await next(tester, 'Invitaciones');
      expect(find.text('Invitaciones'), findsOneWidget);
      expect(
        find.textContaining('No tienes invitaciones pendientes'),
        findsOneWidget,
      );
      // Es la última: no hay flecha hacia delante.
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('la flecha hacia atrás vuelve a la sección anterior', (
      tester,
    ) async {
      await pumpPage(tester);
      await next(tester, 'Pendientes');

      await tester.tap(find.byTooltip('Sección anterior: Guardados'));
      await tester.pumpAndSettle();

      expect(find.text('Guardados'), findsOneWidget);
      expect(projects.otherProjectsCategoryIndex.value, 0);
    });

    testWidgets('la sección elegida queda en el controlador', (tester) async {
      await pumpPage(tester);

      await next(tester, 'Pendientes');

      expect(projects.otherProjectsCategoryIndex.value, 1);
    });

    testWidgets('el contador usa singular y plural', (tester) async {
      await pumpPage(tester);

      projects.savedProjects.add(aProject(id: 'a', owner: 'jefe'));
      await tester.pumpAndSettle();
      expect(find.text('1 proyecto'), findsOneWidget);

      projects.savedProjects.add(aProject(id: 'b', owner: 'jefe'));
      await tester.pumpAndSettle();
      expect(find.text('2 proyectos'), findsOneWidget);
    });
  });

  group('Guardados', () {
    testWidgets('lista lo guardado con «Aplicar»', (tester) async {
      await pumpPage(tester);
      projects.savedProjects.add(aProject(id: 'a', owner: 'jefe'));
      await tester.pumpAndSettle();

      expect(find.text('Proyecto a'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Aplicar'), findsOneWidget);
    });

    testWidgets('un proyecto cerrado dice «Cerrado» y no se puede aplicar', (
      tester,
    ) async {
      await pumpPage(tester);
      projects.savedProjects.add(
        aProject(id: 'a', owner: 'jefe', status: 'closed'),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Cerrado'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('«Quitar de guardados» lo saca de la lista', (tester) async {
      await pumpPage(tester);
      projects.savedProjects.add(aProject(id: 'a', owner: 'jefe'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Quitar de guardados'));
      await tester.pumpAndSettle();

      expect(find.text('Proyecto a'), findsNothing);
      expect(projects.isSaved('a'), isFalse);
    });

    testWidgets('«Aplicar» pide confirmar la postulación', (tester) async {
      await pumpPage(tester);
      projects.savedProjects.add(aProject(id: 'a', owner: 'jefe'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Postularte al proyecto?'), findsOneWidget);
    });
  });

  group('Pendientes y Activos', () {
    testWidgets('lo postulado sale en «Pendientes» con su insignia', (
      tester,
    ) async {
      await pumpPage(tester);
      projects.savedProjects.add(aProject(id: 'a', owner: 'jefe'));
      projects.appliedProjectIds.add('a');
      await tester.pumpAndSettle();

      // Ya no es un guardado suelto: pasó a pendiente.
      expect(find.text('Proyecto a'), findsNothing);

      await next(tester, 'Pendientes');
      expect(find.text('Proyecto a'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('donde ya colabora sale en «Activos» como «Colaborando»', (
      tester,
    ) async {
      await pumpPage(tester);
      projects.activeProjects.add(aProject(id: 'a', owner: 'jefe'));
      await tester.pumpAndSettle();

      await next(tester, 'Pendientes');
      await next(tester, 'Activos');

      expect(find.text('Proyecto a'), findsOneWidget);
      expect(find.text('Colaborando'), findsOneWidget);
    });
  });

  group('Invitaciones', () {
    Future<void> openInvitations(WidgetTester tester) async {
      await next(tester, 'Pendientes');
      await next(tester, 'Activos');
      await next(tester, 'Invitaciones');
    }

    testWidgets('al abrir la sección vuelve a leer las invitaciones', (
      tester,
    ) async {
      await pumpPage(tester);
      final before = repo.pendingReads;

      await openInvitations(tester);

      expect(repo.pendingReads, greaterThan(before));
    });

    testWidgets('muestra el proyecto invitado con Aceptar y Rechazar', (
      tester,
    ) async {
      repo.pending = [_invitation('i1', 'a')];
      repo.projects['a'] = aProject(id: 'a', owner: 'jefe');
      await pumpPage(tester);

      await openInvitations(tester);

      expect(find.text('Proyecto a'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
    });

    testWidgets('«Aceptar» acepta, avisa al controlador y quita la tarjeta', (
      tester,
    ) async {
      repo.pending = [_invitation('i1', 'a')];
      repo.projects['a'] = aProject(id: 'a', owner: 'jefe');
      await pumpPage(tester);
      await openInvitations(tester);

      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(repo.accepted, ['i1']);
      expect(accepted.map((p) => p.id), ['a']);
      expect(find.text('Proyecto a'), findsNothing);
    });

    testWidgets('«Rechazar» rechaza y quita la tarjeta sin activar nada', (
      tester,
    ) async {
      repo.pending = [_invitation('i1', 'a')];
      repo.projects['a'] = aProject(id: 'a', owner: 'jefe');
      await pumpPage(tester);
      await openInvitations(tester);

      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();

      expect(repo.declined, ['i1']);
      expect(accepted, isEmpty);
      expect(find.text('Proyecto a'), findsNothing);
    });

    testWidgets('si el servidor rechaza la respuesta, avisa y la deja', (
      tester,
    ) async {
      repo.pending = [_invitation('i1', 'a')];
      repo.projects['a'] = aProject(id: 'a', owner: 'jefe');
      repo.invitationFailure = const ProjectFailure(
        'El proyecto ya está cerrado.',
      );
      await pumpPage(tester);
      await openInvitations(tester);

      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('El proyecto ya está cerrado.'), findsOneWidget);
      expect(find.text('Proyecto a'), findsOneWidget);
      expect(accepted, isEmpty);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('un proyecto cerrado no ofrece invitación', (tester) async {
      repo.pending = [_invitation('i1', 'a')];
      repo.projects['a'] = aProject(id: 'a', owner: 'jefe', status: 'closed');
      await pumpPage(tester);

      await openInvitations(tester);

      expect(find.text('Proyecto a'), findsNothing);
      expect(invitations.invitations, isEmpty);
    });
  });
}
