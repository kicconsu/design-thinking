import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

import '../../../../support/scripted_project_data_source.dart';

void main() {
  late ScriptedProjectDataSource source;
  late ProjectRepository repo;
  const projectId = DummyData.kircheId;

  setUp(() {
    Get.reset();
    source = ScriptedProjectDataSource(DummyData().projects);
    repo = ProjectRepository(source);
    Get.put<IProjectRepository>(repo);
  });

  tearDown(Get.reset);

  Future<void> join(String userId, {String role = 'collaborator'}) =>
      repo.addProjectMember(
        projectId: projectId,
        userId: userId,
        role: {'name': role},
      );

  group('getProjectMembers', () {
    test('el creador va primero, luego por orden de ingreso', () async {
      await join('ana');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await join('jefe', role: 'owner');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await join('luis');

      final members = await repo.getProjectMembers(projectId);

      expect(members.map((m) => m.userId), ['jefe', 'ana', 'luis']);
      expect(members.first.role, ProjectMemberRole.owner);
      expect(members.first.name, 'Nombre de jefe');
      expect(members.first.career, 'Ingeniería - Uninorte');
      expect(members.last.joinedAt, isNotNull);
    });

    test('quien se fue o lo sacaron ya no aparece', () async {
      await join('ana');
      await join('luis');
      await join('eva');
      source.endMembership(projectId, 'luis', 'left');
      source.endMembership(projectId, 'eva', 'removed');

      final members = await repo.getProjectMembers(projectId);

      expect(members.map((m) => m.userId), ['ana']);
    });

    test('no mezcla miembros de otros proyectos ni cuenta dos veces', () async {
      await join('ana');
      await join('ana');
      await repo.addProjectMember(projectId: 'otro', userId: 'luis');

      final members = await repo.getProjectMembers(projectId);

      expect(members.map((m) => m.userId), ['ana']);
    });

    test('un perfil ilegible o ausente no tumba la lista', () async {
      await join('roto');
      await join('sin-perfil');

      final members = await repo.getProjectMembers(projectId);

      expect(members, hasLength(2));
      // Nombre genérico: "Usuario <inicio del id>", o "Miembro" si el id es corto.
      expect(members.map((m) => m.name).toSet(), {
        'Miembro',
        'Usuario sin-perf',
      });
      expect(members.map((m) => m.career), everyElement(''));
    });

    test('un rol desconocido nunca promueve a creador', () {
      expect(
        ProjectMemberRole.fromName('admin'),
        ProjectMemberRole.collaborator,
      );
      expect(ProjectMemberRole.fromName(null), ProjectMemberRole.collaborator);
      expect(ProjectMemberRole.fromName('creador'), ProjectMemberRole.owner);
    });
  });
}
