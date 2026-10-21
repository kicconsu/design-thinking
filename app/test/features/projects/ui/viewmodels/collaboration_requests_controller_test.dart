import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';

import '../../../../support/dummy_data.dart';
import '../../../../support/scripted_project_data_source.dart';
import '../../../../support/builders.dart';

final _project = aProject(id: 'p1', owner: 'owner-1', title: 'Proyecto');

void main() {
  late InMemoryProjectDataSource source;
  late IProjectRepository repository;
  var isOwner = true;

  CollaborationRequestsController build() => CollaborationRequestsController(
    repository: repository,
    currentUserId: () => 'owner-1',
    isOwner: (_) => isOwner,
  );

  Future<void> setUpWith(InMemoryProjectDataSource ds) async {
    Get.reset();
    isOwner = true;
    source = ds;
    repository = ProjectRepository(source);
    await repository.createJoinRequest(
      projectId: 'p1',
      userId: 'applicant-1',
      status: 'pending',
    );
  }

  tearDown(Get.reset);

  test(
    'aceptar registra al miembro, marca la solicitud y la saca de la lista',
    () async {
      await setUpWith(InMemoryProjectDataSource(DummyData().projects));
      final controller = build();
      await controller.fetchForProject('p1');
      expect(controller.pendingCount('p1'), 1);

      final error = await controller.decide(
        controller.applicants.first,
        project: _project,
        accepted: true,
      );

      expect(error, isNull);
      expect(controller.pendingCount('p1'), 0);
      final members = await source.readProjectMembers(projectId: 'p1');
      expect(members.where((m) => m['user_id'] == 'applicant-1'), hasLength(1));
      final requests = await repository.getJoinRequestsForProject('p1');
      expect(requests.single.statusState, 'accepted');
      expect(requests.single.reviewedBy, 'owner-1');
    },
  );

  test('rechazar no agrega miembros', () async {
    await setUpWith(InMemoryProjectDataSource(DummyData().projects));
    final controller = build();
    await controller.fetchForProject('p1');

    final error = await controller.decide(
      controller.applicants.first,
      project: _project,
      accepted: false,
    );

    expect(error, isNull);
    expect(await source.readProjectMembers(projectId: 'p1'), isEmpty);
    expect(
      (await repository.getJoinRequestsForProject('p1')).single.statusState,
      'rejected',
    );
  });

  test(
    'si el servidor falla, la solicitud sigue y se devuelve el error',
    () async {
      await setUpWith(ScriptedProjectDataSource()..joinRequestFailures = 1);
      final controller = build();
      await controller.fetchForProject('p1');

      final error = await controller.decide(
        controller.applicants.first,
        project: _project,
        accepted: true,
      );

      expect(error, isNotNull);
      expect(controller.pendingCount('p1'), 1);
    },
  );

  test('reintentar tras un fallo a medias no duplica al miembro', () async {
    await setUpWith(ScriptedProjectDataSource()..joinRequestFailures = 1);
    final controller = build();
    await controller.fetchForProject('p1');
    final applicant = controller.applicants.first;

    await controller.decide(applicant, project: _project, accepted: true);
    final retry = await controller.decide(
      applicant,
      project: _project,
      accepted: true,
    );

    expect(retry, isNull);
    final members = await source.readProjectMembers(projectId: 'p1');
    expect(members.where((m) => m['user_id'] == 'applicant-1'), hasLength(1));
  });

  test('quien no es dueño no puede decidir', () async {
    await setUpWith(InMemoryProjectDataSource(DummyData().projects));
    final controller = build();
    await controller.fetchForProject('p1');
    isOwner = false;

    final error = await controller.decide(
      controller.applicants.first,
      project: _project,
      accepted: true,
    );

    expect(error, isNotNull);
    expect(await source.readProjectMembers(projectId: 'p1'), isEmpty);
    expect(controller.pendingCount('p1'), 1);
  });
}
