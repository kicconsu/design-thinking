import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/invitations_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

/// Falla las primeras [failures] veces que se responde una invitación.
class _FlakySource extends InMemoryProjectDataSource {
  _FlakySource(this.failures) : super(DummyData());

  int failures;

  @override
  Future<Map<String, dynamic>> updateInvitationStatus({
    required String invitationId,
    required String status,
  }) async {
    if (failures > 0) {
      failures--;
      throw const RobleApiHttpException(404, 'Not found');
    }
    return super.updateInvitationStatus(
      invitationId: invitationId,
      status: status,
    );
  }
}

/// Deja en espera la lectura de invitaciones hasta que la prueba lo decida.
class _GatedSource extends InMemoryProjectDataSource {
  _GatedSource() : super(DummyData());

  Completer<void>? gate;

  @override
  Future<List<Map<String, dynamic>>> readInvitationsForUser(
    String userId,
  ) async {
    await gate?.future;
    return super.readInvitationsForUser(userId);
  }
}

void main() {
  late InMemoryProjectDataSource source;
  late IProjectRepository repository;
  late String projectId;
  var accepted = <Project>[];

  InvitationsController build({String me = 'ana-id'}) => InvitationsController(
    repository: repository,
    currentUserId: () => me,
    onAccepted: accepted.add,
  );

  Future<void> setUpWith(InMemoryProjectDataSource ds) async {
    Get.reset();
    accepted = [];
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

  test('solo lista las invitaciones pendientes dirigidas al usuario', () async {
    await setUpWith(InMemoryProjectDataSource(DummyData()));
    final controller = build();
    await controller.fetch();

    expect(controller.invitations, hasLength(1));
    expect(controller.invitations.single.email, 'ana@correo.com');
    expect(controller.projects[projectId]?.title, 'Proyecto');
  });

  test(
    'aceptar registra al miembro, marca la invitación y activa el proyecto',
    () async {
      await setUpWith(InMemoryProjectDataSource(DummyData()));
      final controller = build();
      await controller.fetch();

      final error = await controller.respond(
        controller.invitations.single,
        accept: true,
      );

      expect(error, isNull);
      expect(controller.invitations, isEmpty);
      expect(accepted.single.id, projectId);
      final members = await source.readProjectMembers(projectId: projectId);
      expect(members.where((m) => m['user_id'] == 'ana-id'), hasLength(1));
      expect(await repository.getPendingInvitations('ana-id'), isEmpty);
    },
  );

  test('rechazar no agrega miembros ni activa el proyecto', () async {
    await setUpWith(InMemoryProjectDataSource(DummyData()));
    final controller = build();
    await controller.fetch();

    final error = await controller.respond(
      controller.invitations.single,
      accept: false,
    );

    expect(error, isNull);
    expect(accepted, isEmpty);
    expect(
      (await source.readProjectMembers(projectId: projectId))
          .where((m) => m['user_id'] == 'ana-id'),
      isEmpty,
    );
    expect(await repository.getPendingInvitations('ana-id'), isEmpty);
  });

  test(
    'si el servidor falla la invitación sigue y reintentar no duplica',
    () async {
      await setUpWith(_FlakySource(1));
      final controller = build();
      await controller.fetch();
      final invitation = controller.invitations.single;

      final first = await controller.respond(invitation, accept: true);
      expect(first, isNotNull);
      expect(controller.invitations, hasLength(1));

      final retry = await controller.respond(invitation, accept: true);
      expect(retry, isNull);
      final members = await source.readProjectMembers(projectId: projectId);
      expect(members.where((m) => m['user_id'] == 'ana-id'), hasLength(1));
    },
  );

  test('no se puede responder una invitación de otra cuenta', () async {
    await setUpWith(InMemoryProjectDataSource(DummyData()));
    final controller = build();
    await controller.fetch();
    final invitation = controller.invitations.single;

    final other = build(me: 'intruso-id');
    final error = await other.respond(invitation, accept: true);

    expect(error, isNotNull);
    expect(
      await source.readProjectMembers(projectId: projectId),
      isNot(
        contains(
          predicate<Map<String, dynamic>>((m) => m['user_id'] == 'intruso-id'),
        ),
      ),
    );
  });

  test(
    'getMemberProjectIds excluye los proyectos donde solo soy creador',
    () async {
      await setUpWith(InMemoryProjectDataSource(DummyData()));
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

  test('al aceptar, el proyecto entra en Activos sin recargar', () async {
    await setUpWith(InMemoryProjectDataSource(DummyData()));
    Get.put<IProjectRepository>(repository);
    final projects = Get.put(UserProjectsController());
    final controller = InvitationsController(
      repository: repository,
      currentUserId: () => 'ana-id',
    );
    await controller.fetch();

    await controller.respond(controller.invitations.single, accept: true);

    expect(projects.activeProjects.map((p) => p.id), contains(projectId));
  });

  test('aceptar cancela mi solicitud pendiente al mismo proyecto', () async {
    await setUpWith(InMemoryProjectDataSource(DummyData()));
    await repository.createJoinRequest(
      projectId: projectId,
      userId: 'ana-id',
      status: 'pending',
    );
    final controller = build();
    await controller.fetch();

    await controller.respond(controller.invitations.single, accept: true);

    final mine = await repository.getJoinRequestsByUser('ana-id');
    expect(mine.single.statusState, 'cancelled');
  });

  test(
    'cancelPendingJoinRequests solo toca las pendientes de ese proyecto',
    () async {
      await setUpWith(InMemoryProjectDataSource(DummyData()));
      final other = await repository.createProject(
        title: 'Otro',
        description: 'd',
        jobs: const [],
        skills: const [],
      );
      await repository.createJoinRequest(
        projectId: projectId,
        userId: 'ana-id',
        status: 'pending',
      );
      await repository.createJoinRequest(
        projectId: other.id,
        userId: 'ana-id',
        status: 'pending',
      );

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

  test(
    'una invitación a un proyecto donde ya soy miembro no se muestra',
    () async {
      await setUpWith(InMemoryProjectDataSource(DummyData()));
      await repository.addProjectMember(
        projectId: projectId,
        userId: 'ana-id',
        role: {'name': 'member'},
      );
      final controller = build();

      await controller.fetch();

      expect(controller.invitations, isEmpty);
    },
  );

  test('clear descarta una carga que sigue en vuelo', () async {
    final slow = _GatedSource();
    await setUpWith(slow);
    final controller = build();
    slow.gate = Completer<void>();

    final loading = controller.fetch();
    controller.clear();
    slow.gate!.complete();
    await loading;

    expect(controller.invitations, isEmpty);
    expect(controller.projects, isEmpty);
  });
}
