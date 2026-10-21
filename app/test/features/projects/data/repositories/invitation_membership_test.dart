import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

void main() {
  late InMemoryProjectDataSource source;
  late IProjectRepository repository;
  late String projectId;

  Future<void> setUpWith(InMemoryProjectDataSource ds) async {
    Get.reset();
    source = ds;
    repository = ProjectRepository(source);
    final project = await repository.createProject(
      title: 'Proyecto',
      description: 'd',
      jobs: const [],
      skills: const [],
    );
    projectId = project.id;
    await source.createInvitations([
      {
        'project_id': projectId,
        'email': 'ana@correo.com',
        'user_id': 'ana-id',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'project_id': projectId,
        'email': 'otro@correo.com',
        'user_id': 'otro-id',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      },
    ]);
  }

  tearDown(Get.reset);

  test(
    'getMemberProjectIds excluye los proyectos donde solo soy creador',
    () async {
      await setUpWith(InMemoryProjectDataSource(DummyData().projects));
      await repository.addProjectMember(
        projectId: projectId,
        userId: 'creador',
        role: {'name': 'owner'},
      );
      await repository.addProjectMember(
        projectId: projectId,
        userId: 'ana-id',
        role: {'name': 'member'},
      );

      expect(await repository.getMemberProjectIds('creador'), isEmpty);
      expect(await repository.getMemberProjectIds('ana-id'), [projectId]);
    },
  );

  test(
    'cancelPendingJoinRequests solo toca las pendientes de ese proyecto',
    () async {
      await setUpWith(InMemoryProjectDataSource(DummyData().projects));
      final other = await repository.createProject(
        title: 'Otro',
        description: 'd',
        jobs: const [],
        skills: const [],
      );
      await source.createJoinRequest({
        'project_id': projectId,
        'user_id': 'ana-id',
        'status': 'pending',
      });
      await source.createJoinRequest({
        'project_id': other.id,
        'user_id': 'ana-id',
        'status': 'pending',
      });

      final cancelled = await repository.cancelPendingJoinRequests(
        projectId: projectId,
        userId: 'ana-id',
      );

      expect(cancelled, 1);
      final byProject = {
        for (final r in await repository.getJoinRequestsByUser('ana-id'))
          r.projectId: r.statusState,
      };
      expect(byProject[projectId], 'cancelled');
      expect(byProject[other.id], 'pending');
    },
  );
}
