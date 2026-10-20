import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';

void main() {
  late InMemoryTaskDataSource source;
  late TaskRepository repo;
  const projectId = 'p1';

  void member(
    String id,
    String userId, {
    String status = 'active',
    String joinedAt = '2026-01-01T00:00:00Z',
    int? taken,
    int? finished,
  }) => source.members.add({
    '_id': id,
    'project_id': projectId,
    'user_id': userId,
    'status': status,
    'joinedAt': joinedAt,
    'tasks_taken': ?taken,
    'tasks_finished': ?finished,
  });

  Map<String, dynamic> row(String id) =>
      source.members.firstWhere((m) => m['_id'] == id);

  setUp(() {
    source = InMemoryTaskDataSource();
    repo = TaskRepository(source);
  });

  group('project.total_tasks', () {
    test('sigue a crear y borrar tareas', () async {
      final a = await repo.createTask(projectId: projectId, title: 'a');
      await repo.createTask(projectId: projectId, title: 'b');
      expect(source.totalTasksByProject[projectId], 2);

      await repo.deleteTask(a);
      expect(source.totalTasksByProject[projectId], 1);
    });

    test('cambiar de estado no lo mueve', () async {
      final a = await repo.createTask(projectId: projectId, title: 'a');
      await repo.updateTaskStatus(task: a, status: TaskStatus.done);
      expect(source.totalTasksByProject[projectId], 1);
    });

    test('las tareas de otro proyecto no cuentan', () async {
      await repo.createTask(projectId: projectId, title: 'a');
      await repo.createTask(projectId: 'p2', title: 'x');
      expect(source.totalTasksByProject[projectId], 1);
      expect(source.totalTasksByProject['p2'], 1);
    });
  });

  group('tasks_taken', () {
    test('reservar suma una; un campo sin valor cuenta como 0', () async {
      member('m1', 'ana');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final b = await repo.createTask(projectId: projectId, title: 'b');

      await repo.reserveTask(task: a, userId: 'ana');
      expect(row('m1')['tasks_taken'], 1);

      await repo.reserveTask(task: b, userId: 'ana');
      expect(row('m1')['tasks_taken'], 2);
    });

    test('retomar una tarea que ya era suya no vuelve a sumar', () async {
      member('m1', 'ana');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final taken = await repo.reserveTask(task: a, userId: 'ana');
      await repo.updateTaskStatus(task: taken, status: TaskStatus.todo);

      await repo.reserveTask(task: taken, userId: 'ana');

      expect(row('m1')['tasks_taken'], 1);
    });

    test('las tareas soltadas al salir siguen contando', () async {
      member('m1', 'ana');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final b = await repo.createTask(projectId: projectId, title: 'b');
      await repo.reserveTask(task: a, userId: 'ana');
      await repo.reserveTask(task: b, userId: 'ana');

      await repo.releaseUnfinishedTasks(projectId: projectId, userId: 'ana');

      expect(row('m1')['tasks_taken'], 2);
      expect(row('m1')['tasks_finished'], isNull);
    });

    test('borrar una tarea tomada la descuenta', () async {
      member('m1', 'ana', taken: 1);
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final taken = await repo.reserveTask(task: a, userId: 'ana');
      expect(row('m1')['tasks_taken'], 2);

      await repo.deleteTask(taken);

      expect(row('m1')['tasks_taken'], 1);
    });

    test('descontar nunca deja el contador bajo 0', () async {
      member('m1', 'ana', taken: 0);
      final a = await repo.createTask(projectId: projectId, title: 'a');

      // Una copia con responsable que el contador nunca llegó a anotar.
      await repo.deleteTask(a.copyWith(assigneeId: 'ana'));

      expect(row('m1')['tasks_taken'], 0);
    });
  });

  group('tasks_finished', () {
    test('terminar y reabrir lo mueve en los dos sentidos', () async {
      member('m1', 'ana');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final b = await repo.createTask(projectId: projectId, title: 'b');
      final ta = await repo.reserveTask(task: a, userId: 'ana');
      final tb = await repo.reserveTask(task: b, userId: 'ana');

      final doneA = await repo.updateTaskStatus(
        task: ta,
        status: TaskStatus.done,
      );
      expect(row('m1')['tasks_finished'], 1);

      await repo.updateTaskStatus(task: tb, status: TaskStatus.done);
      expect(row('m1')['tasks_finished'], 2);

      await repo.updateTaskStatus(task: doneA, status: TaskStatus.doing);
      expect(row('m1')['tasks_finished'], 1);
    });

    test('la copia vieja de la tarea no engaña: manda la base', () async {
      member('m1', 'ana');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      await repo.reserveTask(task: a, userId: 'ana');

      // `a` es la copia sin responsable, anterior a la reserva.
      await repo.updateTaskStatus(task: a, status: TaskStatus.done);

      expect(row('m1')['tasks_finished'], 1);
    });

    test('es idempotente: repetir no suma de más', () async {
      member('m1', 'ana');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final t = await repo.reserveTask(task: a, userId: 'ana');
      await repo.updateTaskStatus(task: t, status: TaskStatus.done);
      await repo.updateTaskStatus(task: t, status: TaskStatus.done);
      expect(row('m1')['tasks_finished'], 1);
    });

    test('cada quien cuenta las suyas', () async {
      member('m1', 'ana');
      member('m2', 'luis');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final b = await repo.createTask(projectId: projectId, title: 'b');
      final ta = await repo.reserveTask(task: a, userId: 'ana');
      await repo.reserveTask(task: b, userId: 'luis');

      await repo.updateTaskStatus(task: ta, status: TaskStatus.done);

      expect(row('m1')['tasks_finished'], 1);
      expect(row('m2')['tasks_finished'], isNull);
    });

    test('con varias estancias solo anota lo nuevo en la activa', () async {
      // En la estancia anterior terminó dos tareas, que siguen a su nombre.
      member('old', 'ana', status: 'left', finished: 2);
      member('now', 'ana', joinedAt: '2026-03-01T00:00:00Z');
      for (final title in ['x', 'y']) {
        final t = await repo.createTask(projectId: projectId, title: title);
        await source.updateTask(t.id, {
          'assignee_id': 'ana',
          'status': TaskStatus.done.name,
        });
      }

      final c = await repo.createTask(projectId: projectId, title: 'c');
      final tc = await repo.reserveTask(task: c, userId: 'ana');
      await repo.updateTaskStatus(task: tc, status: TaskStatus.done);

      // Ana tiene 3 terminadas en el proyecto: 2 ya anotadas atrás, 1 nueva.
      expect(row('old')['tasks_finished'], 2);
      expect(row('now')['tasks_finished'], 1);
    });

    test('borrar una terminada la descuenta', () async {
      member('m1', 'ana');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final t = await repo.reserveTask(task: a, userId: 'ana');
      final done = await repo.updateTaskStatus(
        task: t,
        status: TaskStatus.done,
      );
      expect(row('m1')['tasks_finished'], 1);

      await repo.deleteTask(done);

      expect(row('m1')['tasks_finished'], 0);
    });
  });

  group('sin fila de miembro', () {
    test('las tareas funcionan igual y no se escribe nada', () async {
      final a = await repo.createTask(projectId: projectId, title: 'a');
      final t = await repo.reserveTask(task: a, userId: 'ana');
      await repo.updateTaskStatus(task: t, status: TaskStatus.done);

      expect(source.members, isEmpty);
      expect(source.progressByProject[projectId], 100);
    });

    test('una tarea sin responsable no toca a nadie', () async {
      member('m1', 'ana');
      final a = await repo.createTask(projectId: projectId, title: 'a');
      await repo.updateTaskStatus(task: a, status: TaskStatus.done);
      expect(row('m1')['tasks_finished'], isNull);
    });
  });
}
