import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_relation.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/invitations_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

/// Devuelve membresías sin la columna `status`, como las filas anteriores a
/// que existiera.
class _LegacyMembersSource extends InMemoryProjectDataSource {
  _LegacyMembersSource(this.projectId) : super(DummyData());

  final String projectId;

  @override
  Future<List<Map<String, dynamic>>> readMembershipsByUser(
    String userId,
  ) async => [
    {
      'project_id': projectId,
      'user_id': userId,
      'role': {'name': 'member'},
    },
  ];
}

void main() {
  late InMemoryProjectDataSource source;
  late IProjectRepository repo;
  late String pid;

  Future<void> setUpWith(InMemoryProjectDataSource ds) async {
    Get.reset();
    source = ds;
    repo = ProjectRepository(source);
    Get.put<IProjectRepository>(repo);
    pid = (await repo.createProject(
      title: 'P',
      description: 'd',
      jobs: const [],
      skills: const [],
    )).id;
  }

  Future<void> invite(String userId, {String status = 'pending'}) =>
      source.createInvitations([
        {
          'project_id': pid,
          'email': '$userId@correo.com',
          'user_id': userId,
          'status': status,
          '_owner': 'dueno',
        },
      ]);

  setUp(() => setUpWith(InMemoryProjectDataSource(DummyData())));
  tearDown(Get.reset);

  group('postular', () {
    test('no se puede si ya colaboro', () async {
      await repo.addProjectMember(projectId: pid, userId: 'u1');

      await expectLater(
        repo.createJoinRequest(projectId: pid, userId: 'u1'),
        throwsA(
          isA<ProjectFailure>().having(
            (e) => e.message,
            'message',
            contains('Ya colaboras'),
          ),
        ),
      );
    });

    test('no se puede dos veces mientras haya una pendiente', () async {
      await repo.createJoinRequest(projectId: pid, userId: 'u1');

      await expectLater(
        repo.createJoinRequest(projectId: pid, userId: 'u1'),
        throwsA(isA<ProjectFailure>()),
      );
    });

    test(
      'no se puede con una invitación pendiente al mismo proyecto',
      () async {
        await invite('u1');

        await expectLater(
          repo.createJoinRequest(projectId: pid, userId: 'u1'),
          throwsA(
            isA<ProjectFailure>().having(
              (e) => e.message,
              'message',
              contains('invitaron'),
            ),
          ),
        );
      },
    );

    test('tras un rechazo se puede volver a postular', () async {
      final first = await repo.createJoinRequest(projectId: pid, userId: 'u1');
      await repo.rejectJoinRequest(requestId: first.id, reviewerId: 'dueno');

      final second = await repo.createJoinRequest(projectId: pid, userId: 'u1');

      expect(second.statusState, 'pending');
    });
  });

  group('membresía', () {
    test(
      'una estancia terminada no cuenta y el reingreso crea una fila nueva',
      () async {
        await repo.addProjectMember(projectId: pid, userId: 'u1');
        source.endMembership(pid, 'u1', 'removed');

        expect(await repo.getMemberProjectIds('u1'), isEmpty);

        await repo.addProjectMember(projectId: pid, userId: 'u1');

        expect(await repo.getMemberProjectIds('u1'), [pid]);
        final rows = await source.readProjectMembers(projectId: pid);
        expect(
          rows.map((r) => r['status']),
          containsAll(['removed', 'active']),
        );
        expect(rows, hasLength(2));
      },
    );

    test(
      'una fila sin status (anterior a la columna) cuenta como activa',
      () async {
        await setUpWith(_LegacyMembersSource('legacy'));

        expect(await repo.getMemberProjectIds('u1'), ['legacy']);
      },
    );

    test('getActiveMemberUserIds ignora ex-miembros y duplicados', () async {
      await repo.addProjectMember(projectId: pid, userId: 'u1');
      await repo.addProjectMember(projectId: pid, userId: 'u2');
      source.endMembership(pid, 'u2', 'left');

      expect(await repo.getActiveMemberUserIds(pid), ['u1']);
    });

    test(
      'el creador (rol owner) no cuenta como miembro de "Otros proyectos"',
      () async {
        await repo.addProjectMember(
          projectId: pid,
          userId: 'u1',
          role: {'name': 'owner'},
        );

        expect(await repo.getMemberProjectIds('u1'), isEmpty);
      },
    );
  });

  group('aceptar solicitud', () {
    test(
      'cierra las demás solicitudes e invitaciones pendientes de esa persona',
      () async {
        final request = await repo.createJoinRequest(
          projectId: pid,
          userId: 'u1',
        );
        // Duplicada y con invitación: el repositorio no deja crearlas así, pero
        // ROBLE no tiene unicidad y pudieron existir.
        await source.createJoinRequest({
          'project_id': pid,
          'user_id': 'u1',
          'status': 'pending',
        });
        await invite('u1');

        await repo.acceptJoinRequest(
          requestId: request.id,
          projectId: pid,
          applicantId: 'u1',
          reviewerId: 'dueno',
        );

        final states = [
          for (final r in await repo.getJoinRequestsByUser('u1')) r.statusState,
        ];
        expect(states.where((s) => s == 'accepted'), hasLength(1));
        expect(states.where((s) => s == 'cancelled'), hasLength(1));
        expect(states.where((s) => s == 'pending'), isEmpty);
        expect(await repo.getPendingInvitations('u1'), isEmpty);
        expect(await repo.getMemberProjectIds('u1'), [pid]);
      },
    );

    test('el dueño no ve solicitudes de quien ya colabora', () async {
      await source.createJoinRequest({
        'project_id': pid,
        'user_id': 'u1',
        'status': 'pending',
      });
      await repo.addProjectMember(projectId: pid, userId: 'u1');
      final controller = CollaborationRequestsController(
        repository: repo,
        currentUserId: () => 'dueno',
        isOwner: (_) => true,
      );

      await controller.fetchForProject(pid);

      expect(controller.applicants, isEmpty);
    });
  });

  group('Activos viene solo de la membresía', () {
    var user = 'u1';
    late UserProjectsController controller;

    setUp(() {
      user = 'u1';
      controller = UserProjectsController(currentUserId: () => user);
    });

    test(
      'una solicitud accepted sin membresía no hace activo a nadie',
      () async {
        await source.createJoinRequest({
          'project_id': pid,
          'user_id': 'u1',
          'status': 'accepted',
        });

        await controller.fetchUserApplications();

        expect(controller.activeProjects, isEmpty);
      },
    );

    test('si lo echan, deja de estar en Activos al recargar', () async {
      await repo.addProjectMember(projectId: pid, userId: 'u1');
      await controller.fetchUserApplications();
      expect(controller.activeProjects.map((p) => p.id), [pid]);

      source.endMembership(pid, 'u1', 'removed');
      await controller.fetchUserApplications();

      expect(controller.activeProjects, isEmpty);
    });

    test('echado, puede ser invitado de nuevo', () async {
      await repo.addProjectMember(projectId: pid, userId: 'u1');
      source.endMembership(pid, 'u1', 'removed');
      await invite('u1');
      final invitations = InvitationsController(
        repository: repo,
        currentUserId: () => 'u1',
        onAccepted: (_) {},
      );

      await invitations.fetch();

      expect(invitations.invitations, hasLength(1));
    });
  });

  group('relationOf', () {
    late UserProjectsController controller;
    const project = Project(
      id: 'p',
      title: 'P',
      imageUrl: '',
      description: '',
      jobs: [],
      skills: [],
    );

    setUp(() {
      Get.reset();
      controller = UserProjectsController(currentUserId: () => 'u1');
    });

    test('sin nada: none', () {
      expect(controller.relationOf(project), ProjectRelation.none);
    });

    test('solo guardado: saved', () {
      controller.savedProjects.add(project);
      expect(controller.relationOf(project), ProjectRelation.saved);
    });

    test('guardado y postulado: pending', () {
      controller.savedProjects.add(project);
      controller.appliedProjectIds.add('p');
      expect(controller.relationOf(project), ProjectRelation.pending);
    });

    test('guardado, postulado e invitado: invited gana', () async {
      final invitations = Get.put(
        InvitationsController(
          repository: ProjectRepository(InMemoryProjectDataSource(DummyData())),
          currentUserId: () => 'u1',
        ),
      );
      final inMemory = InMemoryProjectDataSource(DummyData());
      await inMemory.createInvitations([
        {
          'project_id': 'p',
          'email': 'a@b.co',
          'user_id': 'u1',
          'status': 'pending',
        },
      ]);
      invitations.invitations.add(
        (await ProjectRepository(inMemory).getPendingInvitations('u1')).single,
      );
      controller.savedProjects.add(project);
      controller.appliedProjectIds.add('p');

      expect(controller.relationOf(project), ProjectRelation.invited);
    });

    test('con todo lo anterior y además activo: active gana', () {
      controller.savedProjects.add(project);
      controller.appliedProjectIds.add('p');
      controller.activeProjects.add(project);
      expect(controller.relationOf(project), ProjectRelation.active);
    });

    test('creador: owner gana a todo', () {
      controller.userCreatedProjectIds.add('p');
      controller.activeProjects.add(project);
      expect(controller.relationOf(project), ProjectRelation.owner);
    });
  });
}
