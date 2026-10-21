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

  group('getProjectsParticipatedBy', () {
    test('incluye los que dejó, a diferencia de getProjectsOfPerson', () async {
      final source = InMemoryProjectDataSource(DummyData().projects);
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
      final repository = ProjectRepository(
        InMemoryProjectDataSource(DummyData().projects),
      );
      expect(await repository.getProjectsParticipatedBy('nadie'), isEmpty);
      expect(await repository.getProjectsParticipatedBy(''), isEmpty);
    });
  });
}
