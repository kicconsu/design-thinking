import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/project_failure.dart';

/// Datasource doble: decide qué correos "tienen cuenta" y si el servidor
/// acepta las invitaciones, para poder probar la creación todo-o-nada.
class _InviteTestSource extends InMemoryProjectDataSource {
  _InviteTestSource() : super(DummyData());

  final Set<String> knownEmails = {'ana@correo.com'};
  bool failInvitations = false;
  int cascadeCalls = 0;
  List<Map<String, dynamic>> sentInvitations = [];

  @override
  Future<List<Map<String, dynamic>>> findUsersByEmails(
    List<String> emails,
  ) async {
    return [
      for (final email in emails)
        if (knownEmails.contains(email.trim().toLowerCase()))
          {'email': email.trim().toLowerCase(), 'user_id': 'uuid-$email'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> createInvitations(
    List<Map<String, dynamic>> invitations,
  ) async {
    sentInvitations = invitations;
    if (failInvitations) {
      throw Exception('el servidor rechazó las invitaciones');
    }
    return super.createInvitations(invitations);
  }

  @override
  Future<void> deleteProjectCascade(String projectId) async {
    cascadeCalls++;
    await super.deleteProjectCascade(projectId);
  }
}

void main() {
  group('Invitación de miembros al crear un proyecto', () {
    late _InviteTestSource source;
    late ProjectRepository repo;

    setUp(() {
      source = _InviteTestSource();
      repo = ProjectRepository(source);
    });

    test('validateInviteEmails devuelve sólo los correos sin cuenta', () async {
      final missing = await repo.validateInviteEmails([
        'ana@correo.com',
        'nadie@correo.com',
        'ANA@CORREO.COM ', // repetido en otra mayúscula
      ]);

      expect(missing, ['nadie@correo.com']);
    });

    test(
      'con todos los correos válidos se crea el proyecto y las invitaciones',
      () async {
        final before = (await source.readProjects()).length;

        final project = await repo.createProject(
          title: 'Proyecto con equipo',
          description: 'Descripción',
          jobs: [],
          skills: [],
          inviteEmails: ['ana@correo.com'],
        );

        expect((await source.readProjects()).length, before + 1);
        expect(source.sentInvitations, hasLength(1));
        expect(source.sentInvitations.single['project_id'], project.id);
        expect(source.sentInvitations.single['email'], 'ana@correo.com');
        expect(source.sentInvitations.single['user_id'], 'uuid-ana@correo.com');
        expect(source.sentInvitations.single['status'], 'pending');
        expect(source.cascadeCalls, 0);
      },
    );

    test('un correo sin cuenta aborta todo: no se escribe nada', () async {
      final before = (await source.readProjects()).length;

      await expectLater(
        repo.createProject(
          title: 'Nunca debe existir',
          description: 'x',
          jobs: [],
          skills: [],
          inviteEmails: ['ana@correo.com', 'fantasma@correo.com'],
        ),
        throwsA(
          isA<ProjectFailure>().having(
            (e) => e.message,
            'message',
            allOf(contains('fantasma@correo.com'), contains('no se creó')),
          ),
        ),
      );

      expect((await source.readProjects()).length, before);
      expect(source.sentInvitations, isEmpty);
      expect(source.cascadeCalls, 0);
    });

    test(
      'si las invitaciones fallan se deshace la creación completa',
      () async {
        final before = (await source.readProjects()).length;
        source.failInvitations = true;

        await expectLater(
          repo.createProject(
            title: 'Debe deshacerse',
            description: 'x',
            jobs: [],
            skills: [],
            inviteEmails: ['ana@correo.com'],
          ),
          throwsA(
            isA<ProjectFailure>().having(
              (e) => e.message,
              'message',
              contains('no se creó'),
            ),
          ),
        );

        expect(source.cascadeCalls, 1);
        expect((await source.readProjects()).length, before);
      },
    );

    test('crear sin invitaciones no toca el directorio de correos', () async {
      final before = (await source.readProjects()).length;

      final project = await repo.createProject(
        title: 'Solo proyecto',
        description: 'x',
        jobs: [],
        skills: [],
      );

      expect(project.id, isNotEmpty);
      expect((await source.readProjects()).length, before + 1);
      expect(source.sentInvitations, isEmpty);
      expect(source.cascadeCalls, 0);
    });
  });
}
