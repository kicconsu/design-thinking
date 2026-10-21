import 'package:flutter_test/flutter_test.dart';

import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/subtask.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';

void main() {
  late InMemoryTaskDataSource source;
  late TaskRepository repo;
  late DateTime now;
  const projectId = 'p1';

  setUp(() {
    now = DateTime.utc(2026, 3, 14, 15, 30);
    source = InMemoryTaskDataSource();
    repo = TaskRepository(source, clock: () => now);
  });

  Future<ProjectTask> create() =>
      repo.createTask(projectId: projectId, title: 'a');

  Future<DateTime?> storedFinishedAt() async =>
      (await repo.getTasks(projectId)).single.finishedAt;

  const open = Subtask(title: 'x');
  const done = Subtask(title: 'x', done: true);

  group('por estado', () {
    test('una tarea nueva no tiene finished_at', () async {
      final task = await create();

      expect(task.finishedAt, isNull);
      expect(await storedFinishedAt(), isNull);
    });

    test('pasar a terminada escribe el instante actual en UTC', () async {
      final task = await create();

      final updated = await repo.updateTaskStatus(
        task: task,
        status: TaskStatus.done,
      );

      expect(updated.finishedAt, now);
      final stored = await storedFinishedAt();
      expect(stored, now);
      expect(stored!.isUtc, isTrue);

      // A Roble se manda texto ISO en UTC.
      final raw = (await source.readTasks(projectId)).single['finished_at'];
      expect(raw, now.toIso8601String());
      expect(raw, endsWith('Z'));
    });

    test('reabrirla lo borra', () async {
      final task = await create();
      final finished = await repo.updateTaskStatus(
        task: task,
        status: TaskStatus.done,
      );

      final reopened = await repo.updateTaskStatus(
        task: finished,
        status: TaskStatus.doing,
      );

      expect(reopened.finishedAt, isNull);
      expect(await storedFinishedAt(), isNull);
    });

    test('moverla entre pendiente y en progreso no lo toca', () async {
      final task = await create();

      await repo.updateTaskStatus(task: task, status: TaskStatus.doing);

      expect(await storedFinishedAt(), isNull);
      expect(
        (await source.readTasks(projectId)).single.containsKey('finished_at'),
        isFalse,
      );
    });

    test('terminada otra vez, guarda el instante del último cierre', () async {
      var task = await create();
      task = await repo.updateTaskStatus(task: task, status: TaskStatus.done);
      task = await repo.updateTaskStatus(task: task, status: TaskStatus.doing);

      now = DateTime.utc(2026, 3, 20, 9);
      task = await repo.updateTaskStatus(task: task, status: TaskStatus.done);

      expect(task.finishedAt, DateTime.utc(2026, 3, 20, 9));
      expect(await storedFinishedAt(), DateTime.utc(2026, 3, 20, 9));
    });

    test('volver a marcarla terminada no mueve la hora de cierre', () async {
      var task = await create();
      task = await repo.updateTaskStatus(task: task, status: TaskStatus.done);

      now = DateTime.utc(2026, 4, 1);
      await repo.updateTaskStatus(task: task, status: TaskStatus.done);

      expect(await storedFinishedAt(), DateTime.utc(2026, 3, 14, 15, 30));
    });
  });

  group('por checklist', () {
    test(
      'completar el checklist escribe la hora; desmarcar la borra',
      () async {
        final task = await create();
        final saved = await repo.saveTaskProgress(
          task: task,
          description: '',
          subtasks: [done, done],
        );
        expect(saved.finishedAt, now);
        expect(await storedFinishedAt(), now);

        final reopened = await repo.saveTaskProgress(
          task: saved,
          description: '',
          subtasks: [done, open],
        );

        expect(reopened.status, TaskStatus.doing);
        expect(reopened.finishedAt, isNull);
        expect(await storedFinishedAt(), isNull);
      },
    );

    test('guardar de nuevo una tarea ya terminada no mueve la hora', () async {
      final task = await create();
      final saved = await repo.saveTaskProgress(
        task: task,
        description: '',
        subtasks: [done],
      );

      now = DateTime.utc(2026, 5, 1);
      await repo.saveTaskProgress(
        task: saved,
        description: 'ajuste',
        subtasks: [done],
      );

      expect(await storedFinishedAt(), DateTime.utc(2026, 3, 14, 15, 30));
    });
  });

  group('lectura', () {
    test('un finished_at ilegible o vacío se lee como "sin fecha"', () async {
      await source.createTask({
        'project_id': projectId,
        'title': 'rota',
        'status': 'done',
        'finished_at': 'no es una fecha',
      });
      await source.createTask({
        'project_id': projectId,
        'title': 'vacía',
        'status': 'done',
        'finished_at': '',
      });

      final tasks = await repo.getTasks(projectId);

      expect(tasks.map((t) => t.finishedAt), [null, null]);
    });
  });

  group('ProjectTask.copyWith(finishedAt)', () {
    final at = DateTime.utc(2026, 3, 14);
    final task = ProjectTask(
      id: 't',
      projectId: 'p',
      title: 'a',
      finishedAt: at,
    );

    test('conserva, cambia o borra la hora', () {
      final other = DateTime.utc(2026, 4, 1);

      expect(task.copyWith(title: 'b').finishedAt, at);
      expect(task.copyWith(finishedAt: other).finishedAt, other);
      expect(task.copyWith(clearFinishedAt: true).finishedAt, isNull);
    });
  });
}
