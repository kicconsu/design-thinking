import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/viewmodels/task_board_controller.dart';

void main() {
  late InMemoryTaskDataSource source;
  late TaskRepository repo;

  setUp(() {
    Get.reset();
    source = InMemoryTaskDataSource();
    repo = TaskRepository(source);
    Get.put<ITaskRepository>(repo);
  });

  tearDown(Get.reset);

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
        await c.createTask(
          title: 'Login',
          deadlineDay: DateTime(2026, 3, 20, 8),
        ),
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
}
