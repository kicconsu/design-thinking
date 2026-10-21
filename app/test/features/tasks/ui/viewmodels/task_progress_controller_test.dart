import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/subtask.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/viewmodels/task_progress_controller.dart';

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

  group('TaskProgressController', () {
    test('solo quien reservó edita, y el resto recibe el motivo', () async {
      final task = await reserved('ana');
      final ana = TaskProgressController(task, currentUserId: () => 'ana');
      final luis = TaskProgressController(task, currentUserId: () => 'luis');

      expect(ana.canEdit, isTrue);
      expect(ana.readOnlyReason, isNull);
      expect(luis.canEdit, isFalse);
      expect(luis.readOnlyReason, contains('reservó'));

      expect(await luis.save('hack'), isNotNull);
      expect((await repo.getTasks(projectId)).single.description, isEmpty);
    });

    test('una tarea pendiente se lee pero pide reservarla', () async {
      final task = await repo.createTask(projectId: projectId, title: 'x');
      final c = TaskProgressController(task, currentUserId: () => 'ana');
      expect(c.canEdit, isFalse);
      expect(c.readOnlyReason, contains('Reserva'));
    });

    test('guardar actualiza la tarea con el estado resultante', () async {
      final task = await reserved('ana');
      final c = TaskProgressController(task, currentUserId: () => 'ana');
      c.setChecklist(const [Subtask(title: 'GET', done: true)]);

      expect(await c.save('  hecho  '), isNull);

      expect(c.task.value.status, TaskStatus.done);
      expect(c.task.value.description, 'hecho');
      expect(c.isSaving.value, isFalse);
    });

    test('comentar agrega arriba, firma como "Tú" y valida', () async {
      final task = await reserved('ana');
      final c = TaskProgressController(task, currentUserId: () => 'ana');

      expect(await c.addComment('   '), isNotNull);
      expect(await c.addComment('Hola'), isNull);

      expect(c.comments.single.body, 'Hola');
      expect(c.authorOf(c.comments.single), 'Tú');

      final anon = TaskProgressController(task, currentUserId: () => '');
      expect(await anon.addComment('Hola'), contains('cuenta'));
    });
  });
}
