import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
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

    test('sin repositorio de métricas también funciona', () async {
      Get.delete<ITrustRepository>(force: true);
      final controller = await build();

      await controller.fetchForProject('p1');

      expect(controller.pendingCount('p1'), 2);
    });
  });
}
