import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/task_deadline.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';

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

  group('ProjectTask.isOverdueAt', () {
    final deadline = DateTime.utc(2026, 3, 20, 4, 59, 59);
    ProjectTask task({DateTime? due, TaskStatus status = TaskStatus.doing}) =>
        ProjectTask(
          id: 't',
          projectId: 'p',
          title: 'a',
          status: status,
          deadline: due,
        );

    test('vencida: pasó la fecha y no está terminada', () {
      expect(
        task(due: deadline)
            .isOverdueAt(deadline.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('hasta el último instante del día no está vencida', () {
      expect(task(due: deadline).isOverdueAt(deadline), isFalse);
      expect(
        task(due: deadline)
            .isOverdueAt(deadline.subtract(const Duration(days: 3))),
        isFalse,
      );
    });

    test('una terminada nunca está vencida', () {
      final later = deadline.add(const Duration(days: 9));
      expect(
        task(due: deadline, status: TaskStatus.done).isOverdueAt(later),
        isFalse,
      );
    });

    test('sin fecha límite no vence', () {
      expect(task().isOverdueAt(DateTime.utc(2099)), isFalse);
    });
  });

  group('TaskDeadline.canEdit', () {
    ProjectTask task({String? creator, TaskStatus status = TaskStatus.todo}) =>
        ProjectTask(
          id: 't',
          projectId: 'p',
          title: 'a',
          status: status,
          creatorId: creator,
        );

    bool can(ProjectTask t, String user, {String owner = 'jefe'}) =>
        TaskDeadline.canEdit(task: t, userId: user, projectOwnerId: owner);

    test('quien creó la tarea puede', () {
      expect(can(task(creator: 'ana'), 'ana'), isTrue);
    });

    test('el creador del proyecto puede, aunque no creara la tarea', () {
      expect(can(task(creator: 'ana'), 'jefe'), isTrue);
    });

    test('nadie más puede', () {
      expect(can(task(creator: 'ana'), 'luis'), isFalse);
    });

    test('una tarea terminada no se edita, ni por su creador', () {
      expect(
        can(task(creator: 'ana', status: TaskStatus.done), 'ana'),
        isFalse,
      );
      expect(
        can(task(creator: 'ana', status: TaskStatus.done), 'jefe'),
        isFalse,
      );
    });

    test('sin sesión o sin creador conocido nadie coincide', () {
      expect(can(task(creator: 'ana'), ''), isFalse);
      expect(can(task(), 'ana'), isFalse);
      expect(can(task(), '', owner: ''), isFalse);
    });
  });

  group('TaskDeadline.changeNote', () {
    // Mediodía local: el día local es el mismo en cualquier zona horaria.
    final march20 = DateTime(2026, 3, 20, 12).toUtc();
    final march25 = DateTime(2026, 3, 25, 12).toUtc();

    test('fijar una fecha nueva', () {
      expect(
        TaskDeadline.changeNote(after: march20),
        'Fecha límite fijada: 20/03/2026.',
      );
    });

    test('cambiarla dice de cuál a cuál', () {
      expect(
        TaskDeadline.changeNote(before: march20, after: march25),
        'Fecha límite cambiada: 20/03/2026 → 25/03/2026.',
      );
    });

    test('quitarla dice cuál era', () {
      expect(
        TaskDeadline.changeNote(before: march20),
        'Fecha límite quitada (era 20/03/2026).',
      );
    });

    test('formatDay usa dos dígitos', () {
      expect(TaskDeadline.formatDay(DateTime(2026, 1, 5, 12)), '05/01/2026');
    });
  });
}
