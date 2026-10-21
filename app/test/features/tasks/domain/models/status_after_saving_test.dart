import 'package:flutter_test/flutter_test.dart';

import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/subtask.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';

void main() {
  group('statusAfterSaving', () {
    const done = Subtask(title: 'a', done: true);
    const open = Subtask(title: 'b');

    test('todas hechas -> terminada', () {
      expect(
        ProjectTask.statusAfterSaving(TaskStatus.doing, [done, done]),
        TaskStatus.done,
      );
    });

    test('desmarcar una terminada la devuelve a en progreso', () {
      expect(
        ProjectTask.statusAfterSaving(TaskStatus.done, [done, open]),
        TaskStatus.doing,
      );
    });

    test('a medias, o sin checklist, no cambia el estado', () {
      expect(
        ProjectTask.statusAfterSaving(TaskStatus.doing, [done, open]),
        TaskStatus.doing,
      );
      // Sin subtareas "todas hechas" no significa terminada.
      expect(
        ProjectTask.statusAfterSaving(TaskStatus.doing, const []),
        TaskStatus.doing,
      );
    });

    test('checklistProgress es la fracción de subtareas hechas', () {
      expect(
        const ProjectTask(
          id: '1',
          projectId: 'p',
          title: 't',
        ).checklistProgress,
        0,
      );
      expect(
        const ProjectTask(
          id: '1',
          projectId: 'p',
          title: 't',
          subtasks: [done, open],
        ).checklistProgress,
        0.5,
      );
    });
  });
}
