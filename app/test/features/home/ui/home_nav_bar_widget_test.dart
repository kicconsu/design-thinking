import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../support/dummy_data.dart';

import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/project_info_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/pages/task_board_page.dart';
import 'package:imker/features/tasks/ui/pages/task_progress_page.dart';
import 'package:imker/routes/app_routes.dart';
import 'package:imker/core/utils/app_keys.dart';

/// Un Home de mentira: la ruta real `/home` con un botón que apila [next].
class _FakeHome extends StatelessWidget {
  const _FakeHome({required this.next});

  final Widget Function() next;

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeViewModel>();
    return Scaffold(
      body: Column(
        children: [
          Obx(() => Text('home tab ${home.currentIndex.value}')),
          TextButton(onPressed: () => Get.to(next), child: const Text('abrir')),
        ],
      ),
    );
  }
}

void main() {
  late ProjectTask task;

  setUp(() async {
    Get.reset();
    Get.put(HomeViewModel());
    Get.put<IProjectRepository>(
      ProjectRepository(InMemoryProjectDataSource(DummyData().projects)),
    );
    Get.put(UserProjectsController());
    final tasks = TaskRepository(InMemoryTaskDataSource());
    Get.put<ITaskRepository>(tasks);
    task = await tasks.createTask(
      projectId: DummyData.kircheId,
      title: 'Una tarea',
    );
  });

  tearDown(Get.reset);

  final pages = <String, Widget Function()>{
    'información del proyecto': () =>
        ProjectInfoPage(project: DummyData.kircheProject),
    'gabinete de tareas': () => TaskBoardPage(
      project: DummyData.kircheProject,
      currentUserId: () => 'ana',
    ),
    'progreso de tarea': () => TaskProgressPage(
      project: DummyData.kircheProject,
      task: task,
      currentUserId: () => 'ana',
    ),
  };

  for (final entry in pages.entries) {
    testWidgets('${entry.key}: la barra marca Proyectos y navega', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.home,
          getPages: [
            GetPage(
              name: AppRoutes.home,
              page: () => _FakeHome(next: entry.value),
            ),
          ],
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // La barra está, con sus tres pestañas.
      expect(find.text('DESCUBRIR'), findsOneWidget);
      expect(find.text('PROYECTOS'), findsOneWidget);
      expect(find.text('PERFIL'), findsOneWidget);

      // Tocar Perfil cierra la página y deja Home en esa pestaña.
      await tester.tap(find.byKey(AppKeys.navTab('profile')));
      await tester.pumpAndSettle();

      expect(find.text('home tab 2'), findsOneWidget);
      expect(find.text('abrir'), findsOneWidget);
      expect(find.text('PERFIL'), findsNothing);
    });
  }
}
