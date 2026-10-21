import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/pages/task_board_page.dart';
import 'package:imker/core/utils/app_keys.dart';

void main() {
  late InMemoryTaskDataSource source;
  late TaskRepository repo;
  const projectId = DummyData.kircheId;

  setUp(() {
    Get.reset();
    source = InMemoryTaskDataSource();
    repo = TaskRepository(source);
    Get.put<ITaskRepository>(repo);
  });

  tearDown(Get.reset);

  testWidgets('la página lista por pestaña y reserva desde la tarjeta', (
    tester,
  ) async {
    final task = await repo.createTask(
      projectId: projectId,
      title: 'Escribir pruebas',
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: TaskBoardPage(
          project: DummyData.kircheProject,
          currentUserId: () => 'demo-user',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gabinete de tareas'), findsOneWidget);
    expect(find.text('Escribir pruebas'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.reserveTask(task.id)));
    await tester.pumpAndSettle();
    // Salió de Pendientes...
    expect(find.text('Escribir pruebas'), findsNothing);
    expect(find.text('No hay tareas pendientes.'), findsOneWidget);

    // ...y está en En Progreso, reservada por mí.
    await tester.tap(find.byKey(AppKeys.taskBoardTab(1)));
    await tester.pumpAndSettle();
    expect(find.text('Escribir pruebas'), findsOneWidget);
    expect(find.text('Reservada por Tú'), findsOneWidget);

    // La notificación de «Tarea reservada» deja un temporizador de 3 s.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
