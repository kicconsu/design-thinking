import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';

void main() {
  late InMemoryTaskDataSource source;
  late TaskRepository repo;
  const projectId = 'p1';

  setUp(() {
    source = InMemoryTaskDataSource();
    repo = TaskRepository(source);
  });

  test('progressOf: sin tareas es 0 y no divide entre cero', () {
    expect(ProjectTask.progressOf(const []), 0);
  });

  test('crear tareas deja el progreso en 0 y contando', () async {
    await repo.createTask(projectId: projectId, title: 'a');
    expect(source.progressByProject[projectId], 0);
  });

  test('cada cambio de estado recalcula el porcentaje de done', () async {
    final a = await repo.createTask(projectId: projectId, title: 'a');
    final b = await repo.createTask(projectId: projectId, title: 'b');
    await repo.createTask(projectId: projectId, title: 'c');

    await repo.updateTaskStatus(task: a, status: TaskStatus.done);
    expect(source.progressByProject[projectId], closeTo(100 / 3, 1e-9));

    // doing no cuenta como terminada.
    await repo.updateTaskStatus(task: b, status: TaskStatus.doing);
    expect(source.progressByProject[projectId], closeTo(100 / 3, 1e-9));

    await repo.updateTaskStatus(task: b, status: TaskStatus.done);
    expect(source.progressByProject[projectId], closeTo(200 / 3, 1e-9));

    // volver atrás también baja el progreso.
    await repo.updateTaskStatus(task: a, status: TaskStatus.todo);
    expect(source.progressByProject[projectId], closeTo(100 / 3, 1e-9));
  });

  test('borrar una tarea recalcula; borrar la última deja 0', () async {
    final a = await repo.createTask(projectId: projectId, title: 'a');
    final b = await repo.createTask(projectId: projectId, title: 'b');
    await repo.updateTaskStatus(task: a, status: TaskStatus.done);

    await repo.deleteTask(b);
    expect(source.progressByProject[projectId], 100);

    await repo.deleteTask(a);
    expect(source.progressByProject[projectId], 0);
  });

  test('las tareas de otro proyecto no cuentan', () async {
    final a = await repo.createTask(projectId: projectId, title: 'a');
    await repo.createTask(projectId: 'p2', title: 'x');
    await repo.updateTaskStatus(task: a, status: TaskStatus.done);
    expect(source.progressByProject[projectId], 100);
    expect(source.progressByProject['p2'], 0);
  });

  test('un estado desconocido se lee como pendiente', () {
    expect(TaskStatus.fromName('algo'), TaskStatus.todo);
    expect(TaskStatus.fromName(null), TaskStatus.todo);
  });

  group('releaseUnfinishedTasks', () {
    test('libera las sin terminar y deja las terminadas a su nombre', () async {
      final pending = await repo.createTask(projectId: projectId, title: 'a');
      final doing = await repo.createTask(projectId: projectId, title: 'b');
      final done = await repo.createTask(projectId: projectId, title: 'c');
      final other = await repo.createTask(projectId: projectId, title: 'd');
      await repo.reserveTask(task: pending, userId: 'ana');
      await repo.reserveTask(task: doing, userId: 'ana');
      await repo.reserveTask(task: done, userId: 'ana');
      await repo.updateTaskStatus(task: done, status: TaskStatus.done);
      await repo.reserveTask(task: other, userId: 'luis');

      final released = await repo.releaseUnfinishedTasks(
        projectId: projectId,
        userId: 'ana',
      );

      final tasks = {
        for (final t in await repo.getTasks(projectId)) t.title: t,
      };
      expect(released, 2);
      expect(tasks['a']!.assigneeId, isNull);
      expect(tasks['a']!.status, TaskStatus.todo);
      expect(tasks['b']!.assigneeId, isNull);
      expect(tasks['c']!.assigneeId, 'ana');
      expect(tasks['c']!.status, TaskStatus.done);
      expect(tasks['d']!.assigneeId, 'luis');
    });

    test('no cambia el progreso del proyecto', () async {
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final b = await repo.createTask(projectId: projectId, title: 'b');
      await repo.reserveTask(task: a, userId: 'ana');
      await repo.reserveTask(task: b, userId: 'ana');
      await repo.updateTaskStatus(task: b, status: TaskStatus.done);
      final before = source.progressByProject[projectId];

      await repo.releaseUnfinishedTasks(projectId: projectId, userId: 'ana');

      expect(source.progressByProject[projectId], before);
    });

    test('sin tareas suyas devuelve 0', () async {
      await repo.createTask(projectId: projectId, title: 'a');

      expect(
        await repo.releaseUnfinishedTasks(projectId: projectId, userId: 'ana'),
        0,
      );
    });
  });
}
