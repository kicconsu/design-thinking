import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/project_info_page.dart';
import 'package:imker/features/projects/ui/viewmodels/project_members_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

/// Perfiles distintos por usuario, y uno que falla.
class _Source extends InMemoryProjectDataSource {
  _Source(super.data);

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async {
    if (userId == 'roto') throw StateError('sin permiso');
    if (userId == 'sin-perfil') return null;
    return {
      'name': 'Nombre de $userId',
      'career': {'program': 'Ingeniería', 'institution': 'Uninorte'},
    };
  }
}

void main() {
  late _Source source;
  late ProjectRepository repo;
  const projectId = DummyData.kircheId;

  setUp(() {
    Get.reset();
    source = _Source(DummyData());
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

  group('ProjectMembersController', () {
    test('carga, marca "yo" y distingue "todavía no" de "vacío"', () async {
      await join('ana');
      final c = ProjectMembersController(projectId, currentUserId: () => 'ana');
      expect(c.loaded.value, isFalse);

      await c.load();

      expect(c.loaded.value, isTrue);
      expect(c.members.single.userId, 'ana');
      expect(c.isMe(c.members.single), isTrue);
      expect(c.error.value, isNull);
    });

    test('sin sesión nadie es "yo"', () async {
      await join('ana');
      final c = ProjectMembersController(projectId, currentUserId: () => '');
      await c.load();
      expect(c.isMe(c.members.single), isFalse);
    });
  });

  testWidgets('la pestaña Miembros lista a la gente con su papel', (
    tester,
  ) async {
    Get.put(UserProjectsController());
    await join('jefe', role: 'owner');
    await join('ana');

    await tester.pumpWidget(
      GetMaterialApp(
        home: ProjectInfoPage(
          project: DummyData.kircheProject,
          currentUserId: () => 'ana',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Miembros'));
    await tester.pumpAndSettle();

    expect(find.text('2 miembros'), findsOneWidget);
    expect(find.text('Nombre de jefe'), findsOneWidget);
    expect(find.text('Nombre de ana (Tú)'), findsOneWidget);
    expect(find.text('Creador'), findsOneWidget);
    expect(find.text('Colaborador'), findsOneWidget);
    expect(find.text('Ingeniería - Uninorte'), findsNWidgets(2));
  });
}
