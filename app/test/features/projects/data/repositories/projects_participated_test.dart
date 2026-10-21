import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';

import '../../../../support/fake_profile_repository.dart';
import '../../../../support/fake_trust_repository.dart';
import '../../../../support/fake_project_repository.dart';

void main() {
  late FakeTrustRepository trust;
  late FakeProjectRepository projects;

  setUp(() {
    Get.reset();
    trust = FakeTrustRepository();
    projects = FakeProjectRepository();
    Get.put<IProfileRepository>(FakeProfileRepository());
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
