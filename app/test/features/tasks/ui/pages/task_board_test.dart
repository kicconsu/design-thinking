import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/pages/task_board_page.dart';
import 'package:imker/features/tasks/ui/viewmodels/task_board_controller.dart';

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

  group('reserveTask', () {
    test('queda doing con el responsable y no toca el progreso', () async {
      final task = await repo.createTask(projectId: projectId, title: 'a');
      final writes = source.progressByProject[projectId];

      final reserved = await repo.reserveTask(task: task, userId: 'ana');

      expect(reserved.status, TaskStatus.doing);
      expect(reserved.assigneeId, 'ana');
      final stored = (await repo.getTasks(projectId)).single;
      expect(stored.status, TaskStatus.doing);
      expect(stored.assigneeId, 'ana');
      expect(source.progressByProject[projectId], writes);
    });

    test('si otra persona ya la tomó, no la pisa', () async {
      final task = await repo.createTask(projectId: projectId, title: 'a');
      await repo.reserveTask(task: task, userId: 'ana');

      // `task` es la copia vieja, que aún se ve pendiente.
      expect(
        () => repo.reserveTask(task: task, userId: 'luis'),
        throwsA(isA<ProjectFailure>()),
      );
      expect((await repo.getTasks(projectId)).single.assigneeId, 'ana');
    });
  });

  group('TaskBoardController', () {
    test('crea tareas pendientes y las reserva para el usuario', () async {
      final c = TaskBoardController(
        DummyData.kircheProject,
        currentUserId: () => 'ana',
      );

      expect(await c.createTask(title: 'Login'), isNull);
      expect(c.tasksOf(TaskStatus.todo), hasLength(1));

      expect(await c.reserveTask(c.tasks.single), isNull);
      expect(c.tasksOf(TaskStatus.todo), isEmpty);
      expect(c.tasksOf(TaskStatus.doing).single.assigneeId, 'ana');
      expect(c.assigneeLabel(c.tasks.single), 'Tú');
    });

    test('la fecha límite elegida vence al final de ese día', () async {
      final c = TaskBoardController(
        DummyData.kircheProject,
        currentUserId: () => 'ana',
      );

      expect(
        await c.createTask(title: 'Login', deadlineDay: DateTime(2026, 3, 20, 8)),
        isNull,
      );

      expect(
        c.tasks.single.deadline,
        DateTime(2026, 3, 20, 23, 59, 59, 999).toUtc(),
      );
    });

    test('sin fecha elegida, la tarea no tiene deadline', () async {
      final c = TaskBoardController(
        DummyData.kircheProject,
        currentUserId: () => 'ana',
      );

      await c.createTask(title: 'Login');

      expect(c.tasks.single.deadline, isNull);
    });

    test('reservar sin sesión devuelve un mensaje y no escribe', () async {
      final c = TaskBoardController(
        DummyData.kircheProject,
        currentUserId: () => '',
      );
      await c.createTask(title: 'Login');

      expect(await c.reserveTask(c.tasks.single), isNotNull);
      expect(c.tasksOf(TaskStatus.todo), hasLength(1));
    });

    test('si se la ganaron, avisa y recarga', () async {
      final c = TaskBoardController(
        DummyData.kircheProject,
        currentUserId: () => 'luis',
      );
      await c.createTask(title: 'Login');
      final stale = c.tasks.single;
      await repo.reserveTask(task: stale, userId: 'ana');

      expect(await c.reserveTask(stale), contains('ya fue reservada'));
      await Future<void>.delayed(Duration.zero);
      expect(c.tasks.single.assigneeId, 'ana');
    });
  });

  testWidgets('la página lista por pestaña y reserva desde la tarjeta', (
    tester,
  ) async {
    await repo.createTask(projectId: projectId, title: 'Escribir pruebas');

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

    await tester.tap(find.text('Reservar tarea'));
    await tester.pumpAndSettle();
    // Salió de Pendientes...
    expect(find.text('Escribir pruebas'), findsNothing);
    expect(find.text('No hay tareas pendientes.'), findsOneWidget);

    // ...y está en En Progreso, reservada por mí.
    await tester.tap(find.text('En Progreso'));
    await tester.pumpAndSettle();
    expect(find.text('Escribir pruebas'), findsOneWidget);
    expect(find.text('Reservada por Tú'), findsOneWidget);

    // La notificación de «Tarea reservada» deja un temporizador de 3 s.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
