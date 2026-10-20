import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';

/// Una fuente donde escribir comentarios falla, para probar que el aviso es
/// parte del cambio pero no lo deshace.
class _NoCommentsSource extends InMemoryTaskDataSource {
  @override
  Future<Map<String, dynamic>> createContribution(
    Map<String, dynamic> contributionData,
  ) => throw const RobleApiNetworkException('sin red');
}

void main() {
  late InMemoryTaskDataSource source;
  late TaskRepository repo;
  const projectId = 'p1';
  // Mediodía local de cada día: el día local no depende de la zona horaria.
  final march20 = DateTime(2026, 3, 20, 23, 59, 59, 999).toUtc();
  final march25 = DateTime(2026, 3, 25, 23, 59, 59, 999).toUtc();

  setUp(() {
    source = InMemoryTaskDataSource()..currentUserId = 'ana';
    repo = TaskRepository(source);
  });

  Future<ProjectTask> create({DateTime? deadline}) =>
      repo.createTask(projectId: projectId, title: 'a', deadline: deadline);

  test('cada tarea recuerda quién la creó', () async {
    final task = await create();

    expect(task.creatorId, 'ana');
    expect((await repo.getTasks(projectId)).single.creatorId, 'ana');
  });

  test('cambia la fecha límite y la guarda en UTC', () async {
    final task = await create(deadline: march20);

    final updated = await repo.updateTaskDeadline(
      task: task,
      deadline: march25,
      userId: 'ana',
    );

    expect(updated.deadline, march25);
    final stored = (await repo.getTasks(projectId)).single;
    expect(stored.deadline, march25);
    expect(stored.deadline!.isUtc, isTrue);
  });

  test('pone fecha a una tarea que no tenía', () async {
    final task = await create();

    final updated = await repo.updateTaskDeadline(
      task: task,
      deadline: march20,
      userId: 'ana',
    );

    expect(updated.deadline, march20);
  });

  test('quita la fecha límite (a null)', () async {
    final task = await create(deadline: march20);

    final updated = await repo.updateTaskDeadline(
      task: task,
      deadline: null,
      userId: 'ana',
    );

    expect(updated.deadline, isNull);
    expect((await repo.getTasks(projectId)).single.deadline, isNull);
  });

  test('deja un comentario automático con el cambio', () async {
    final task = await create(deadline: march20);

    await repo.updateTaskDeadline(task: task, deadline: march25, userId: 'ana');

    final comments = await repo.getComments(task);
    expect(comments, hasLength(1));
    expect(comments.single.userId, 'ana');
    expect(
      comments.single.body,
      'Fecha límite cambiada: 20/03/2026 → 25/03/2026.',
    );
  });

  test('quitarla también lo avisa', () async {
    final task = await create(deadline: march20);

    await repo.updateTaskDeadline(task: task, deadline: null, userId: 'ana');

    expect(
      (await repo.getComments(task)).single.body,
      'Fecha límite quitada (era 20/03/2026).',
    );
  });

  test('si la fecha no cambia, no escribe ni comenta', () async {
    final task = await create(deadline: march20);

    await repo.updateTaskDeadline(task: task, deadline: march20, userId: 'ana');

    expect(await repo.getComments(task), isEmpty);
  });

  test('una tarea terminada no se edita', () async {
    final task = await create(deadline: march20);
    await repo.updateTaskStatus(task: task, status: TaskStatus.done);

    expect(
      repo.updateTaskDeadline(task: task, deadline: march25, userId: 'ana'),
      throwsA(isA<ProjectFailure>()),
    );
    expect((await repo.getTasks(projectId)).single.deadline, march20);
    expect(await repo.getComments(task), isEmpty);
  });

  test('si la tarea ya no existe, avisa', () async {
    final task = await create();
    await source.deleteTask(task.id);

    expect(
      repo.updateTaskDeadline(task: task, deadline: march25, userId: 'ana'),
      throwsA(
        isA<ProjectFailure>().having(
          (e) => e.message,
          'message',
          'La tarea ya no existe.',
        ),
      ),
    );
  });

  test('si el aviso falla, la fecha igual queda cambiada', () async {
    final noComments = _NoCommentsSource()..currentUserId = 'ana';
    final repo = TaskRepository(noComments);
    final task = await repo.createTask(
      projectId: projectId,
      title: 'a',
      deadline: march20,
    );

    final updated = await repo.updateTaskDeadline(
      task: task,
      deadline: march25,
      userId: 'ana',
    );

    expect(updated.deadline, march25);
    expect((await repo.getTasks(projectId)).single.deadline, march25);
  });
}
