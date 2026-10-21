import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/project_members_controller.dart';

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
    source = _Source(DummyData().projects);
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
}
