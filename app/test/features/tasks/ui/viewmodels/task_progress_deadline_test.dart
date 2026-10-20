import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/viewmodels/task_progress_controller.dart';

void main() {
  late InMemoryTaskDataSource source;
  late TaskRepository repo;
  const projectId = 'p1';
  // «Hoy» fijo: 14 de marzo de 2026, a media tarde.
  DateTime clock() => DateTime(2026, 3, 14, 15, 30);
  final march20 = DateTime(2026, 3, 20, 23, 59, 59, 999).toUtc();

  setUp(() {
    Get.reset();
    source = InMemoryTaskDataSource()..currentUserId = 'ana';
    repo = TaskRepository(source);
    Get.put<ITaskRepository>(repo);
  });

  tearDown(Get.reset);

  Future<ProjectTask> create({DateTime? deadline}) =>
      repo.createTask(projectId: projectId, title: 'a', deadline: deadline);

  TaskProgressController controllerFor(ProjectTask task, String user) =>
      TaskProgressController(
        task,
        currentUserId: () => user,
        projectOwnerId: 'jefe',
        clock: clock,
      );

  group('quién puede editar la fecha límite', () {
    test('quien creó la tarea', () async {
      final c = controllerFor(await create(), 'ana');
      expect(c.canEditDeadline, isTrue);
    });

    test('el creador del proyecto', () async {
      final c = controllerFor(await create(), 'jefe');
      expect(c.canEditDeadline, isTrue);
    });

    test('nadie más', () async {
      final c = controllerFor(await create(), 'luis');
      expect(c.canEditDeadline, isFalse);
      expect(
        await c.setDeadline(DateTime(2026, 3, 20)),
        contains('Solo quien'),
      );
      expect((await repo.getTasks(projectId)).single.deadline, isNull);
    });

    test('nadie, si la tarea está terminada', () async {
      final task = await create(deadline: march20);
      final done = await repo.updateTaskStatus(
        task: task,
        status: TaskStatus.done,
      );
      final c = controllerFor(done, 'ana');

      expect(c.canEditDeadline, isFalse);
      expect(await c.setDeadline(null), contains('terminada'));
    });
  });

  group('setDeadline', () {
    test('cambia el día: la tarea vence al final de ese día', () async {
      final c = controllerFor(await create(), 'ana');

      expect(await c.setDeadline(DateTime(2026, 3, 20, 8)), isNull);

      expect(c.task.value.deadline, march20);
      expect((await repo.getTasks(projectId)).single.deadline, march20);
    });

    test('quita la fecha con null', () async {
      final c = controllerFor(await create(deadline: march20), 'ana');

      expect(await c.setDeadline(null), isNull);

      expect(c.task.value.deadline, isNull);
    });

    test('hoy se puede, ayer no', () async {
      final c = controllerFor(await create(), 'ana');

      expect(await c.setDeadline(DateTime(2026, 3, 13)), contains('anterior'));
      expect(c.task.value.deadline, isNull);

      expect(await c.setDeadline(DateTime(2026, 3, 14)), isNull);
      expect(c.task.value.deadline, isNotNull);
    });

    test('el cambio aparece en los comentarios ya cargados', () async {
      final c = controllerFor(await create(deadline: march20), 'ana');
      await c.loadComments();
      expect(c.comments, isEmpty);

      await c.setDeadline(DateTime(2026, 3, 25));

      expect(c.comments, hasLength(1));
      expect(c.comments.single.body, contains('→ 25/03/2026'));
    });

    test('no pierde el checklist sin guardar', () async {
      final c = controllerFor(await create(), 'ana');
      c.setChecklist(const []);

      await c.setDeadline(DateTime(2026, 3, 20));

      expect(c.checklist, isEmpty);
    });
  });

  group('vencida', () {
    test('pasó el día límite y sigue sin terminar', () async {
      final task = await create(
        deadline: DateTime(2026, 3, 10, 23, 59).toUtc(),
      );
      expect(controllerFor(task, 'ana').isOverdue, isTrue);
    });

    test('el mismo día límite todavía no', () async {
      final task = await create(
        deadline: DateTime(2026, 3, 14, 23, 59, 59, 999).toUtc(),
      );
      expect(controllerFor(task, 'ana').isOverdue, isFalse);
    });

    test('terminada, no está vencida', () async {
      final task = await create(
        deadline: DateTime(2026, 3, 10, 23, 59).toUtc(),
      );
      final done = await repo.updateTaskStatus(
        task: task,
        status: TaskStatus.done,
      );
      expect(controllerFor(done, 'ana').isOverdue, isFalse);
    });
  });
}
