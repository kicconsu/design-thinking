import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/auth/domain/models/authentication_user.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

/// Perfiles con nombre propio por usuario.
class _Source extends InMemoryProjectDataSource {
  _Source(super.data);

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async => {
    'name': 'Nombre de $userId',
    'career': {'program': 'Ingeniería'},
  };
}

class _Auth implements IAuthRepository {
  _Auth({required this.anonymous});

  final bool anonymous;

  @override
  Future<bool> restoreSession() async => true;

  @override
  Future<AuthenticationUser?> getLoggedUser() async =>
      AuthenticationUser(email: 'yo@x.co', name: 'Yo', password: '', id: 'yo');

  @override
  bool get isAnonymous => anonymous;

  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles implements IProfileRepository {
  @override
  Future<UserProfile> getProfileOf(String userId) async =>
      const UserProfile(program: 'Derecho', skills: ['Oratoria']);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Source source;
  late ProjectRepository repo;

  setUp(() {
    Get.reset();
    source = _Source(DummyData().projects);
    repo = ProjectRepository(source);
    Get.put<IProjectRepository>(repo);
    Get.put<IProfileRepository>(_Profiles());
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

class _FailingProjects implements IProjectRepository {
  @override
  Future<List<Project>> getProjectsOfPerson(String userId) async =>
      throw const ProjectFailure('Sin conexión.');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
