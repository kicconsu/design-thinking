import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/member_profile_page.dart';
import 'package:imker/features/projects/ui/pages/project_info_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';

class _Profiles implements IProfileRepository {
  @override
  Future<UserProfile> getProfileOf(String userId) async =>
      const UserProfile(program: 'Derecho', skills: ['Oratoria']);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Dueño de los proyectos de la fuente en memoria.
const _creator = 'demo-owner';
const _projectId = DummyData.kircheId;

void main() {
  late InMemoryProjectDataSource source;
  late ProjectRepository repo;
  late TaskRepository tasks;

  setUp(() async {
    Get.reset();
    source = InMemoryProjectDataSource(DummyData());
    repo = ProjectRepository(source);
    tasks = TaskRepository(InMemoryTaskDataSource());
    Get.put<IProjectRepository>(repo);
    Get.put<ITaskRepository>(tasks);
    Get.put<IProfileRepository>(_Profiles());
    await repo.addProjectMember(
      projectId: _projectId,
      userId: _creator,
      role: {'name': 'owner'},
    );
    await repo.addProjectMember(projectId: _projectId, userId: 'ana');
  });

  tearDown(Get.reset);

  Future<List<Object?>> statusesOf(String userId) async => [
    for (final r in await source.readProjectMembers(projectId: _projectId))
      if (r['user_id'] == userId) r['status'],
  ];

  /// Ana tiene una tarea terminada y otra en curso.
  Future<void> giveAnaTasks() async {
    final done = await tasks.createTask(projectId: _projectId, title: 'hecha');
    final doing = await tasks.createTask(projectId: _projectId, title: 'viva');
    await tasks.reserveTask(task: done, userId: 'ana');
    await tasks.updateTaskStatus(task: done, status: TaskStatus.done);
    await tasks.reserveTask(task: doing, userId: 'ana');
  }

  group('ficha de un miembro', () {
    const ana = ProjectMember(userId: 'ana', name: 'Ana Pérez');

    Future<void> open(
      WidgetTester tester, {
      required bool viewerIsCreator,
      String viewer = _creator,
      ProjectMember member = ana,
    }) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          home: MemberProfilePage(
            member: member,
            projectId: _projectId,
            viewerIsCreator: viewerIsCreator,
            currentUserId: () => viewer,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra sus tareas reales en este proyecto', (tester) async {
      await giveAnaTasks();

      await open(tester, viewerIsCreator: true);

      expect(find.text('En este proyecto'), findsOneWidget);
      expect(find.text('TERMINADA'), findsOneWidget);
      expect(find.text('EN CURSO'), findsOneWidget);
    });

    testWidgets('el creador ve «Quitar del proyecto» sobre un colaborador', (
      tester,
    ) async {
      await open(tester, viewerIsCreator: true);

      expect(find.text('Quitar del proyecto'), findsOneWidget);
    });

    testWidgets('un colaborador no ve el botón', (tester) async {
      await open(tester, viewerIsCreator: false, viewer: 'luis');

      expect(find.text('Quitar del proyecto'), findsNothing);
    });

    testWidgets('nadie ve el botón en la ficha del creador ni en la propia', (
      tester,
    ) async {
      await open(
        tester,
        viewerIsCreator: true,
        member: const ProjectMember(
          userId: _creator,
          name: 'Dueño',
          role: ProjectMemberRole.owner,
        ),
      );
      expect(find.text('Quitar del proyecto'), findsNothing);
    });

    testWidgets('cancelar la confirmación no quita a nadie', (tester) async {
      await open(tester, viewerIsCreator: true);

      await tester.tap(find.text('Quitar del proyecto'));
      await tester.pumpAndSettle();
      expect(find.text('¿Quitar a Ana Pérez del proyecto?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(await statusesOf('ana'), ['active']);
    });

    testWidgets('confirmar quita a la persona y libera sus tareas', (
      tester,
    ) async {
      await giveAnaTasks();
      await open(tester, viewerIsCreator: true);

      await tester.tap(find.text('Quitar del proyecto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sus 1 tareas sin terminar'), findsOneWidget);
      await tester.tap(find.text('Quitar'));
      await tester.pumpAndSettle();
      // Deja que termine el aviso.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(await statusesOf('ana'), ['removed']);
      final byTitle = {
        for (final t in await tasks.getTasks(_projectId)) t.title: t,
      };
      expect(byTitle['viva']!.assigneeId, isNull);
      expect(byTitle['viva']!.status, TaskStatus.todo);
      expect(byTitle['hecha']!.assigneeId, 'ana');
    });
  });

  group('salir desde el menú del proyecto', () {
    /// La ficha se abre encima de otra pantalla, como en la app: salir la
    /// cierra y deja la de abajo.
    Future<void> openInfo(WidgetTester tester, String viewer) async {
      Get.put(UserProjectsController());
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Get.to(
                  () => ProjectInfoPage(
                    project: DummyData.kircheProject,
                    currentUserId: () => viewer,
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('el creador no tiene menú de salida', (tester) async {
      await openInfo(tester, _creator);

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('un miembro puede salir tras confirmar', (tester) async {
      await giveAnaTasks();
      final list = Get.find<UserProjectsController>.call;
      await openInfo(tester, 'ana');
      list().activeProjects.add(DummyData.kircheProject);
      await repo.saveProject(userId: 'ana', projectId: _projectId);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir del proyecto'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Para volver tendrás que postular'),
        findsOneWidget,
      );
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(await statusesOf('ana'), ['left']);
      expect(await repo.getSavedProjectIds('ana'), isEmpty);
      expect(list().activeProjects, isEmpty);
      // La pantalla del proyecto se cerró.
      expect(find.byType(ProjectInfoPage), findsNothing);
      final byTitle = {
        for (final t in await tasks.getTasks(_projectId)) t.title: t,
      };
      expect(byTitle['viva']!.assigneeId, isNull);
      expect(byTitle['hecha']!.assigneeId, 'ana');
    });
  });
}
