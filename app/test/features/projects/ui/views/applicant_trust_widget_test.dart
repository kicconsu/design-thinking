import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/person_profile_page.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/ui/views/collaboration_requests_page.dart';
import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
import 'package:imker/features/projects/ui/views/applicant_detail_page.dart';
import 'package:imker/features/projects/domain/models/applicant.dart';
import 'package:imker/features/trust/domain/models/trust_metrics.dart';
import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

import '../../../../support/fake_profile_repository.dart';
import '../../../../support/fake_trust_repository.dart';
import '../../../../support/fake_project_repository.dart';
import '../../../../support/builders.dart';

final _current = aProject(
  id: 'actual',
  owner: 'jefe',
  title: 'Proyecto actual',
);

void main() {
  late FakeTrustRepository trust;
  late FakeProjectRepository projects;

  setUp(() {
    Get.reset();
    trust = FakeTrustRepository()
      ..metrics = const TrustMetrics(
        commitment: 62,
        onTime: 80,
        fulfillment: 88,
        completedProjects: 50,
        hasHistory: true,
      );
    projects = FakeProjectRepository();
    Get.put<IProfileRepository>(FakeProfileRepository());
    Get.put<ITrustRepository>(trust);
    Get.put<IProjectRepository>(projects);
  });

  tearDown(Get.reset);

  group('lista de solicitudes (tarjeta)', () {
    late InMemoryProjectDataSource source;
    late IProjectRepository repository;

    Future<CollaborationRequestsController> build({
      ITrustRepository? trustRepo,
    }) async {
      source = InMemoryProjectDataSource(DummyData().projects);
      repository = ProjectRepository(source);
      for (final user in ['ana', 'luis']) {
        await repository.createJoinRequest(
          projectId: 'p1',
          userId: user,
          status: 'pending',
        );
      }
      return CollaborationRequestsController(
        repository: repository,
        currentUserId: () => 'jefe',
        isOwner: (_) => true,
        trust: trustRepo,
      );
    }

    testWidgets('la tarjeta muestra el compromiso, solo si hay', (
      tester,
    ) async {
      trust.scores = {'ana': 75};
      final controller = await build(trustRepo: trust);
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          home: CollaborationRequestsPage(
            project: aProject(id: 'p1', owner: 'jefe', title: 'Proyecto'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compromiso 75%'), findsOneWidget);
      expect(find.textContaining('Compromiso'), findsOneWidget);
    });
  });

  group('ficha de una solicitud', () {
    Future<void> openApplicant(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.put(
        CollaborationRequestsController(
          repository: ProjectRepository(
            InMemoryProjectDataSource(DummyData().projects),
          ),
          currentUserId: () => 'jefe',
          isOwner: (_) => true,
          trust: trust,
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          home: ApplicantDetailPage(
            project: _current,
            applicant: Applicant(
              id: 'r1',
              projectId: 'actual',
              userId: 'ana-id',
              name: 'Ana Pérez',
              academicInfo: '',
              appliedAgo: 'hace 1h',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra sus cuatro indicadores', (tester) async {
      await openApplicant(tester);

      expect(trust.metricsAsked, ['ana-id']);
      expect(find.text('Índice general de compromiso'), findsOneWidget);
      // El compromiso sale en la barra y también en el encabezado del perfil.
      expect(find.text('62%'), findsNWidgets(2));
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Entrega a tiempo'), findsOneWidget);
      expect(find.text('Cumplimiento'), findsOneWidget);
      expect(find.text('Proyectos completados'), findsOneWidget);
    });

    testWidgets('sin historial explica cuándo aparecen', (tester) async {
      trust.metrics = TrustMetrics.none;
      await openApplicant(tester);

      expect(find.text('Índice general de compromiso'), findsNothing);
      expect(
        find.text(
          'Todavía no hay indicadores. Aparecen cuando colabora en un proyecto.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('si no se pueden calcular, el perfil se ve igual', (
      tester,
    ) async {
      trust.failure = const TrustFailure('Sin conexión.');
      await openApplicant(tester);

      expect(find.text('Litigante en formación.'), findsOneWidget);
      expect(find.text('Índice general de compromiso'), findsNothing);
    });

    testWidgets('el historial muestra solo los proyectos anteriores', (
      tester,
    ) async {
      projects.participated = [
        aProject(id: 'abierto'),
        aProject(id: 'cerrado', status: 'closed'),
        // El proyecto al que aplica no es «anterior» aunque conste cerrado.
        aProject(id: 'actual', status: 'closed'),
      ];
      await openApplicant(tester);
      expect(projects.participatedAsked, ['ana-id']);

      await tester.tap(find.text('Historial de colaboración'));
      await tester.pumpAndSettle();

      expect(find.text('Proyectos anteriores'), findsOneWidget);
      expect(find.text('Proyecto cerrado'), findsOneWidget);
      expect(find.text('Proyecto abierto'), findsNothing);
      expect(find.text('Proyecto actual'), findsNothing);
      expect(find.text('Colaborando ahora'), findsNothing);
      expect(find.text('Proyectos creados'), findsNothing);
    });

    testWidgets('sin poder leer sus proyectos no ofrece el historial', (
      tester,
    ) async {
      projects.participatedFailure = const ProjectFailure('no');
      await openApplicant(tester);

      expect(find.text('Historial de colaboración'), findsNothing);
      expect(find.text('Litigante en formación.'), findsOneWidget);
    });
  });

  group('cualquier otra ficha', () {
    testWidgets('no pide métricas ni ofrece historial', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      projects.participated = [aProject(id: 'cerrado', status: 'closed')];

      await tester.pumpWidget(
        const GetMaterialApp(
          home: PersonProfilePage(userId: 'ana-id', name: 'Ana Pérez'),
        ),
      );
      await tester.pumpAndSettle();

      expect(trust.metricsAsked, isEmpty);
      expect(projects.participatedAsked, isEmpty);
      expect(find.text('Historial de colaboración'), findsNothing);
      expect(find.text('Litigante en formación.'), findsOneWidget);
    });
  });
}
