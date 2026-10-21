import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/subtask.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';

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

  /// Una tarea ya reservada por [userId] (queda `doing`).
  Future<ProjectTask> reserved(String userId, {String title = 'Login'}) async {
    final task = await repo.createTask(projectId: projectId, title: title);
    return repo.reserveTask(task: task, userId: userId);
  }

  group('saveTaskProgress', () {
    test('guarda descripción y checklist y se leen de vuelta', () async {
      final task = await reserved('ana');

      await repo.saveTaskProgress(
        task: task,
        description: 'Integrar el SDK',
        subtasks: const [
          Subtask(title: 'GET', done: true),
          Subtask(title: 'POST'),
        ],
      );

      final stored = (await repo.getTasks(projectId)).single;
      expect(stored.description, 'Integrar el SDK');
      expect(stored.subtasks, const [
        Subtask(title: 'GET', done: true),
        Subtask(title: 'POST'),
      ]);
      expect(stored.status, TaskStatus.doing);
    });

    test(
      'completar el checklist sube el progreso; desmarcar lo baja',
      () async {
        final task = await reserved('ana');

        final saved = await repo.saveTaskProgress(
          task: task,
          description: '',
          subtasks: const [Subtask(title: 'GET', done: true)],
        );

        expect(saved.status, TaskStatus.done);
        expect(source.progressByProject[projectId], 100);

        final back = await repo.saveTaskProgress(
          task: saved,
          description: '',
          subtasks: const [Subtask(title: 'GET')],
        );

        expect(back.status, TaskStatus.doing);
        expect(source.progressByProject[projectId], 0);
      },
    );

    test(
      'un checklist guardado como texto JSON o roto se lee sin fallar',
      () async {
        final task = await reserved('ana');

        await source.updateTask(task.id, {
          'checklist': '[{"title":"GET","done":true},{"x":1},"suelto"]',
        });
        expect((await repo.getTasks(projectId)).single.subtasks, const [
          Subtask(title: 'GET', done: true),
        ]);

        await source.updateTask(task.id, {'checklist': 'no es json'});
        expect((await repo.getTasks(projectId)).single.subtasks, isEmpty);

        await source.updateTask(task.id, {'checklist': null});
        expect((await repo.getTasks(projectId)).single.subtasks, isEmpty);
      },
    );
  });

  group('comentarios', () {
    test('van del más nuevo al más viejo y solo de su tarea', () async {
      final a = await reserved('ana', title: 'A');
      final b = await reserved('ana', title: 'B');
      await repo.addComment(task: a, userId: 'ana', body: 'primero');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.addComment(task: a, userId: 'luis', body: 'segundo');
      await repo.addComment(task: b, userId: 'ana', body: 'de otra tarea');

      final comments = await repo.getComments(a);

      expect(comments.map((c) => c.body), ['segundo', 'primero']);
      expect(comments.first.userId, 'luis');
    });
  });
}
