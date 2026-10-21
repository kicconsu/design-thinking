import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

import '../../../../support/fake_profile_repository.dart';
import '../../../../support/scripted_project_data_source.dart';

void main() {
  late ScriptedProjectDataSource source;
  late ProjectRepository repo;

  setUp(() {
    Get.reset();
    source = ScriptedProjectDataSource(DummyData().projects);
    repo = ProjectRepository(source);
    Get.put<IProjectRepository>(repo);
    Get.put<IProfileRepository>(FakeProfileRepository());
  });

  tearDown(Get.reset);

  Future<String> createProject(String title) async => (await repo.createProject(
    title: title,
    description: 'd',
    jobs: const [],
    skills: const [],
  )).id;

  group('getProjectsOfPerson', () {
    test('junta lo que creó y en lo que colabora, sin repetir', () async {
      final mine = await createProject('Mío');
      final other = await createProject('Ajeno');
      // El creador de los proyectos de la fuente en memoria.
      await repo.addProjectMember(
        projectId: mine,
        userId: 'demo-owner',
        role: {'name': 'owner'},
      );
      await repo.addProjectMember(projectId: other, userId: 'demo-owner');

      final projects = await repo.getProjectsOfPerson('demo-owner');

      expect(projects.where((p) => p.id == mine), hasLength(1));
      expect(projects.map((p) => p.id), containsAll([mine, other]));
    });

    test('quien solo colabora ve esos proyectos', () async {
      final pid = await createProject('P');
      await repo.addProjectMember(projectId: pid, userId: 'ana');

      final projects = await repo.getProjectsOfPerson('ana');

      expect(projects.map((p) => p.id), [pid]);
    });

    test('no cuenta los de los que salió o la sacaron', () async {
      final a = await createProject('A');
      final b = await createProject('B');
      await repo.addProjectMember(projectId: a, userId: 'ana');
      await repo.addProjectMember(projectId: b, userId: 'ana');
      await repo.leaveProject(projectId: a, userId: 'ana');
      await repo.removeMember(
        projectId: b,
        memberUserId: 'ana',
        requestedBy: 'demo-owner',
      );

      expect(await repo.getProjectsOfPerson('ana'), isEmpty);
    });

    test('sin id devuelve vacío', () async {
      expect(await repo.getProjectsOfPerson(''), isEmpty);
    });
  });
}
