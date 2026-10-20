import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/task_deadline.dart';

void main() {
  group('TaskDeadline.endOfDay', () {
    test('es el final del día local, como instante UTC', () {
      final deadline = TaskDeadline.endOfDay(DateTime(2026, 3, 14, 9, 30));

      expect(deadline.isUtc, isTrue);
      expect(deadline, DateTime(2026, 3, 14, 23, 59, 59, 999).toUtc());
    });

    test('ignora la hora del día que se le pasa', () {
      expect(
        TaskDeadline.endOfDay(DateTime(2026, 3, 14, 0, 0)),
        TaskDeadline.endOfDay(DateTime(2026, 3, 14, 23, 0)),
      );
    });

    test('entregar a cualquier hora de ese día es a tiempo', () {
      final deadline = TaskDeadline.endOfDay(DateTime(2026, 3, 14));
      final lateInTheDay = DateTime(2026, 3, 14, 23, 30).toUtc();
      final nextMorning = DateTime(2026, 3, 15, 0, 1).toUtc();

      expect(lateInTheDay.isAfter(deadline), isFalse);
      expect(nextMorning.isAfter(deadline), isTrue);
    });
  });

  group('ProjectTask.copyWith(deadline)', () {
    final due = DateTime.utc(2026, 3, 15);
    final task = ProjectTask(
      id: 't',
      projectId: 'p',
      title: 'a',
      deadline: due,
    );

    test('conserva la fecha si no se toca', () {
      expect(task.copyWith(title: 'b').deadline, due);
    });

    test('puede cambiarla', () {
      final other = DateTime.utc(2026, 4, 1);
      expect(task.copyWith(deadline: other).deadline, other);
    });

    test('puede quitarla (a null)', () {
      expect(task.copyWith(clearDeadline: true).deadline, isNull);
    });
  });
}
