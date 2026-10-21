import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
import 'package:imker/features/projects/domain/models/applicant.dart';
import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

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
