import 'package:flutter_test/flutter_test.dart';

import '../../../../support/dummy_data.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/project_failure.dart';

/// El dueño del proyecto en la fuente en memoria (`_owner` de lo que crea).
const _owner = 'demo-owner';

Matcher _failureWith(String text) => throwsA(
  isA<ProjectFailure>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  late InMemoryProjectDataSource source;
  late ProjectRepository repo;
  late String pid;

  Future<List<Object?>> statusesOf(String userId) async {
    final rows = await source.readProjectMembers(projectId: pid);
    return [
      for (final r in rows)
        if (r['user_id'] == userId) r['status'],
    ];
  }

  setUp(() async {
    source = InMemoryProjectDataSource(DummyData().projects);
    repo = ProjectRepository(source);
    pid = (await repo.createProject(
      title: 'P',
      description: 'd',
      jobs: const [],
      skills: const [],
    )).id;
    await repo.addProjectMember(
      projectId: pid,
      userId: _owner,
      role: {'name': 'owner'},
    );
    await repo.addProjectMember(projectId: pid, userId: 'ana');
    await repo.addProjectMember(projectId: pid, userId: 'luis');
  });

  group('salir', () {
    test('la estancia pasa a left y deja de contar como miembro', () async {
      await repo.leaveProject(projectId: pid, userId: 'ana');

      expect(await statusesOf('ana'), ['left']);
      expect(await repo.getMemberProjectIds('ana'), isEmpty);
      expect(await repo.getActiveMemberUserIds(pid), isNot(contains('ana')));
    });

    test('guarda cuándo salió', () async {
      await repo.leaveProject(projectId: pid, userId: 'ana');

      final row = (await source.readProjectMembers(projectId: pid))
          .firstWhere((r) => r['user_id'] == 'ana');
      expect(DateTime.tryParse(row['leftAt'].toString()), isNotNull);
    });

    test('borra su guardado del proyecto', () async {
      await repo.saveProject(userId: 'ana', projectId: pid);

      await repo.leaveProject(projectId: pid, userId: 'ana');

      expect(await repo.getSavedProjectIds('ana'), isEmpty);
    });

    test('no toca a los demás', () async {
      await repo.leaveProject(projectId: pid, userId: 'ana');

      expect(await statusesOf('luis'), ['active']);
      expect(await statusesOf(_owner), ['active']);
    });

    test('repetirlo no falla (ya no hay estancia activa)', () async {
      await repo.leaveProject(projectId: pid, userId: 'ana');

      await repo.leaveProject(projectId: pid, userId: 'ana');

      expect(await statusesOf('ana'), ['left']);
    });

    test('cierra todas las filas activas si había duplicados', () async {
      // Roble no tiene UNIQUE: dos estancias activas del mismo par.
      source.insertRawMember({
        '_id': 'dup',
        'project_id': pid,
        'user_id': 'ana',
        'role': {'name': 'member'},
        'status': 'active',
      });

      await repo.leaveProject(projectId: pid, userId: 'ana');

      expect(await statusesOf('ana'), everyElement('left'));
    });

    test('el creador no puede salir', () async {
      await expectLater(
        repo.leaveProject(projectId: pid, userId: _owner),
        _failureWith('creador'),
      );
      expect(await statusesOf(_owner), ['active']);
    });

    test('reingresar crea una fila nueva y conserva el historial', () async {
      await repo.leaveProject(projectId: pid, userId: 'ana');

      await repo.addProjectMember(projectId: pid, userId: 'ana');

      expect(await statusesOf('ana'), ['left', 'active']);
    });
  });

  group('quitar', () {
    test('el creador saca a un colaborador: pasa a removed', () async {
      await repo.removeMember(
        projectId: pid,
        memberUserId: 'ana',
        requestedBy: _owner,
      );

      expect(await statusesOf('ana'), ['removed']);
      expect(await repo.getMemberProjectIds('ana'), isEmpty);
    });

    test('conserva el guardado de quien fue sacado', () async {
      await repo.saveProject(userId: 'ana', projectId: pid);

      await repo.removeMember(
        projectId: pid,
        memberUserId: 'ana',
        requestedBy: _owner,
      );

      expect(await repo.getSavedProjectIds('ana'), [pid]);
    });

    test('un colaborador no puede sacar a nadie', () async {
      await expectLater(
        repo.removeMember(
          projectId: pid,
          memberUserId: 'luis',
          requestedBy: 'ana',
        ),
        _failureWith('Solo el creador'),
      );
      expect(await statusesOf('luis'), ['active']);
    });

    test('no se puede sacar al creador', () async {
      await expectLater(
        repo.removeMember(
          projectId: pid,
          memberUserId: _owner,
          requestedBy: _owner,
        ),
        _failureWith('Salir'),
      );
    });

    test('repetirlo no falla', () async {
      for (var i = 0; i < 2; i++) {
        await repo.removeMember(
          projectId: pid,
          memberUserId: 'ana',
          requestedBy: _owner,
        );
      }

      expect(await statusesOf('ana'), ['removed']);
    });

    test('quien fue sacado puede volver a postular', () async {
      await repo.removeMember(
        projectId: pid,
        memberUserId: 'ana',
        requestedBy: _owner,
      );

      final request = await repo.createJoinRequest(
        projectId: pid,
        userId: 'ana',
      );

      expect(request.statusState, 'pending');
    });
  });
}
