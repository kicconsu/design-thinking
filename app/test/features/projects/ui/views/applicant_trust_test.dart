import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/person_profile_page.dart';
import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/ui/views/collaboration_requests_page.dart';
import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
import 'package:imker/features/projects/ui/views/applicant_detail_page.dart';
import 'package:imker/features/projects/domain/models/applicant.dart';
import 'package:imker/features/trust/domain/models/trust_metrics.dart';
import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

class _Profiles implements IProfileRepository {
  @override
  Future<UserProfile> getProfileOf(String userId) async => const UserProfile(
    program: 'Derecho',
    institution: 'Uninorte',
    bio: 'Litigante en formación.',
    skills: ['Oratoria'],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Trust implements ITrustRepository {
  TrustMetrics metrics = const TrustMetrics(
    commitment: 62,
    onTime: 80,
    fulfillment: 88,
    completedProjects: 50,
    hasHistory: true,
  );
  Map<String, int> scores = {};
  TrustFailure? failure;
  final metricsAsked = <String>[];
  final scoresAsked = <List<String>>[];

  @override
  Future<TrustMetrics> getTrustMetricsOf(String userId) async {
    metricsAsked.add(userId);
    if (failure != null) throw failure!;
    return metrics;
  }

  @override
  Future<Map<String, int>> getCommitmentScores(Iterable<String> userIds) async {
    scoresAsked.add(userIds.toList());
    if (failure != null) throw failure!;
    return scores;
  }
}

/// Solo lo que la ficha le pide al repositorio de proyectos.
class _Projects implements IProjectRepository {
  List<Project> participated = [];
  bool participatedFails = false;
  final participatedAsked = <String>[];

  @override
  Future<List<Project>> getProjectsOfPerson(String userId) async => [];

  @override
  Future<List<Project>> getProjectsParticipatedBy(String userId) async {
    participatedAsked.add(userId);
    if (participatedFails) throw const ProjectFailure('no');
    return participated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Project _project(String id, {String status = 'open'}) => Project(
  id: id,
  title: 'Proyecto $id',
  imageUrl: '',
  description: 'd',
  jobs: const [],
  skills: const [],
  status: status,
);

const _current = Project(
  id: 'actual',
  owner: 'jefe',
  title: 'Proyecto actual',
  imageUrl: '',
  description: '',
  jobs: [],
  skills: [],
);

void main() {
  late _Trust trust;
  late _Projects projects;

  setUp(() {
    Get.reset();
    trust = _Trust();
    projects = _Projects();
    Get.put<IProfileRepository>(_Profiles());
    Get.put<ITrustRepository>(trust);
    Get.put<IProjectRepository>(projects);
  });

  tearDown(Get.reset);

  group('lista de solicitudes', () {
    late InMemoryProjectDataSource source;
    late IProjectRepository repository;

    Future<CollaborationRequestsController> build({
      ITrustRepository? trustRepo,
    }) async {
      source = InMemoryProjectDataSource();
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

    Applicant by(CollaborationRequestsController c, String user) =>
        c.applicants.firstWhere((a) => a.userId == user);

    test('cada solicitud trae su compromiso, con una sola consulta', () async {
      trust.scores = {'ana': 75};
      final controller = await build(trustRepo: trust);

      await controller.fetchForProject('p1');

      expect(by(controller, 'ana').commitmentScore, 75);
      expect(by(controller, 'luis').commitmentScore, isNull);
      expect(trust.scoresAsked, hasLength(1));
      expect(trust.scoresAsked.single, unorderedEquals(['ana', 'luis']));
    });

    test('si no se puede calcular, la lista sale igual sin ese dato', () async {
      trust.failure = const TrustFailure('Sin conexión.');
      final controller = await build(trustRepo: trust);

      await controller.fetchForProject('p1');

      expect(controller.pendingCount('p1'), 2);
      expect(by(controller, 'ana').commitmentScore, isNull);
    });

    testWidgets('la tarjeta muestra el compromiso, solo si hay', (
      tester,
    ) async {
      trust.scores = {'ana': 75};
      final controller = await build(trustRepo: trust);
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          home: CollaborationRequestsPage(
            project: const Project(
              id: 'p1',
              owner: 'jefe',
              title: 'Proyecto',
              imageUrl: '',
              description: '',
              jobs: [],
              skills: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compromiso 75%'), findsOneWidget);
      expect(find.textContaining('Compromiso'), findsOneWidget);
    });

    test('sin repositorio de métricas también funciona', () async {
      Get.delete<ITrustRepository>(force: true);
      final controller = await build();

      await controller.fetchForProject('p1');

      expect(controller.pendingCount('p1'), 2);
    });
  });

  group('getProjectsParticipatedBy', () {
    test('incluye los que dejó, a diferencia de getProjectsOfPerson', () async {
      final source = InMemoryProjectDataSource();
      final repository = ProjectRepository(source);
      await source.addProjectMember(
        projectId: DummyData.kircheId,
        userId: 'ana',
      );
      await source.addProjectMember(
        projectId: DummyData.aquaNetId,
        userId: 'ana',
      );
      await source.endMembership(DummyData.aquaNetId, 'ana', 'left');

      final participated = await repository.getProjectsParticipatedBy('ana');
      final current = await repository.getProjectsOfPerson('ana');

      expect(participated.map((p) => p.id), {
        DummyData.kircheId,
        DummyData.aquaNetId,
      });
      expect(current.map((p) => p.id), [DummyData.kircheId]);
    });

    test('sin estancias, o sin id, no hay nada', () async {
      final repository = ProjectRepository(InMemoryProjectDataSource());
      expect(await repository.getProjectsParticipatedBy('nadie'), isEmpty);
      expect(await repository.getProjectsParticipatedBy(''), isEmpty);
    });
  });

  group('ficha de una solicitud', () {
    Future<void> openApplicant(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.put(
        CollaborationRequestsController(
          repository: ProjectRepository(InMemoryProjectDataSource()),
          currentUserId: () => 'jefe',
          isOwner: (_) => true,
          trust: trust,
        ),
      );
      await tester.pumpWidget(
        const GetMaterialApp(
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

    testWidgets('sin historial dice que aparecerán cuando colabore', (
      tester,
    ) async {
      trust.metrics = TrustMetrics.none;
      await openApplicant(tester);

      expect(find.text('Índice general de compromiso'), findsNothing);
      expect(
        find.text('Aparecerán cuando colabore en proyectos.'),
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
        _project('abierto'),
        _project('cerrado', status: 'closed'),
        // El proyecto al que aplica no es «anterior» aunque conste cerrado.
        _project('actual', status: 'closed'),
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
      projects.participatedFails = true;
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
      projects.participated = [_project('cerrado', status: 'closed')];

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
