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
    // La regla vive en TaskDeadline.canEdit; aquí solo se comprueba que el
    // controlador la aplica con el usuario y el creador del proyecto.
    test('el controlador aplica la regla y rechaza el cambio', () async {
      final task = await create(deadline: march20);
      expect(controllerFor(task, 'ana').canEditDeadline, isTrue);
      expect(controllerFor(task, 'jefe').canEditDeadline, isTrue);

      final other = controllerFor(task, 'luis');
      expect(other.canEditDeadline, isFalse);
      expect(
        await other.setDeadline(DateTime(2026, 3, 25)),
        contains('Solo quien'),
      );
      expect((await repo.getTasks(projectId)).single.deadline, march20);

      final done = await repo.updateTaskStatus(
        task: task,
        status: TaskStatus.done,
      );
      final finished = controllerFor(done, 'ana');
      expect(finished.canEditDeadline, isFalse);
      expect(await finished.setDeadline(null), contains('terminada'));
    });
  });

  group('setDeadline', () {
    test('cambia el día: la tarea vence al final de ese día', () async {
      final c = controllerFor(await create(), 'ana');

      expect(await c.setDeadline(DateTime(2026, 3, 20, 8)), isNull);

      expect(c.task.value.deadline, march20);
      expect((await repo.getTasks(projectId)).single.deadline, march20);

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
}
