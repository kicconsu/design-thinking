import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
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
}
