import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/pages/task_progress_page.dart';
import 'package:imker/features/tasks/ui/widgets/task_card.dart';

void main() {
  late InMemoryTaskDataSource source;
  late TaskRepository repo;
  const projectId = DummyData.kircheId;
  // «Hoy» fijo: 14 de marzo de 2026, a media tarde.
  DateTime clock() => DateTime(2026, 3, 14, 15, 30);
  final march20 = DateTime(2026, 3, 20, 23, 59, 59, 999).toUtc();
  final march10 = DateTime(2026, 3, 10, 23, 59, 59, 999).toUtc();

  setUp(() {
    Get.reset();
    source = InMemoryTaskDataSource()..currentUserId = 'ana';
    repo = TaskRepository(source);
    Get.put<ITaskRepository>(repo);
  });

  tearDown(Get.reset);

  Future<ProjectTask> create({DateTime? deadline}) =>
      repo.createTask(projectId: projectId, title: 'Login', deadline: deadline);

  group('TaskCard', () {
    Future<void> pumpCard(WidgetTester tester, ProjectTask task) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TaskCard(task: task, clock: clock),
            ),
          ),
        );

    testWidgets('muestra cuándo vence', (tester) async {
      await pumpCard(tester, await create(deadline: march20));

      expect(find.text('Vence el 20/03/2026'), findsOneWidget);
    });

    testWidgets('una vencida y sin terminar lo marca', (tester) async {
      await pumpCard(tester, await create(deadline: march10));

      expect(find.text('Vencida el 10/03/2026'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('una terminada fuera de plazo ya no se marca vencida', (
      tester,
    ) async {
      final task = (await create(deadline: march10))
          .copyWith(status: TaskStatus.done);
      await pumpCard(tester, task);

      expect(find.textContaining('Vencida'), findsNothing);
      expect(find.text('Límite: 10/03/2026'), findsOneWidget);
    });

    testWidgets('sin fecha límite no muestra nada', (tester) async {
      await pumpCard(tester, await create());

      expect(find.textContaining('Vence'), findsNothing);
      expect(find.byIcon(Icons.event_outlined), findsNothing);
    });
  });

  group('TaskProgressPage', () {
    Future<void> pump(
      WidgetTester tester,
      ProjectTask task,
      String user,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: TaskProgressPage(
            project: DummyData.kircheProject, // creador: demo-owner
            task: task,
            currentUserId: () => user,
            clock: clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('quien creó la tarea ve la fecha y los botones', (
      tester,
    ) async {
      await pump(tester, await create(deadline: march20), 'ana');

      expect(find.text('Vence el 20/03/2026'), findsOneWidget);
      expect(find.byKey(const Key('task.deadline.edit')), findsOneWidget);
      expect(find.byKey(const Key('task.deadline.clear')), findsOneWidget);
    });

    testWidgets('el creador del proyecto también los ve', (tester) async {
      await pump(tester, await create(deadline: march20), 'demo-owner');

      expect(find.byKey(const Key('task.deadline.edit')), findsOneWidget);
    });

    testWidgets('otra persona ve la fecha pero no puede cambiarla', (
      tester,
    ) async {
      await pump(tester, await create(deadline: march20), 'luis');

      expect(find.text('Vence el 20/03/2026'), findsOneWidget);
      expect(find.byKey(const Key('task.deadline.edit')), findsNothing);
      expect(find.byKey(const Key('task.deadline.clear')), findsNothing);
    });

    testWidgets('otra persona, sin fecha, no ve nada de fecha límite', (
      tester,
    ) async {
      await pump(tester, await create(), 'luis');

      expect(find.byKey(const Key('task.deadline')), findsNothing);
    });

    testWidgets('una tarea terminada no se puede editar', (tester) async {
      final task = (await create(deadline: march20))
          .copyWith(status: TaskStatus.done);
      await pump(tester, task, 'ana');

      expect(find.byKey(const Key('task.deadline.edit')), findsNothing);
    });

    testWidgets('la vencida se marca', (tester) async {
      await pump(tester, await create(deadline: march10), 'ana');

      expect(find.text('Vencida el 10/03/2026'), findsOneWidget);
    });

    testWidgets('quitar la fecha la borra y deja el aviso', (tester) async {
      await pump(tester, await create(deadline: march20), 'ana');

      await tester.tap(find.byKey(const Key('task.deadline.clear')));
      await tester.pumpAndSettle();

      expect(find.text('Sin fecha límite'), findsOneWidget);
      expect((await repo.getTasks(projectId)).single.deadline, isNull);
      final task = (await repo.getTasks(projectId)).single;
      expect(
        (await repo.getComments(task)).single.body,
        'Fecha límite quitada (era 20/03/2026).',
      );
    });

    testWidgets('cambiarla con el selector de fecha', (tester) async {
      await pump(tester, await create(deadline: march20), 'ana');

      await tester.tap(find.byKey(const Key('task.deadline.edit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Vence el 25/03/2026'), findsOneWidget);
      expect(
        (await repo.getTasks(projectId)).single.deadline,
        DateTime(2026, 3, 25, 23, 59, 59, 999).toUtc(),
      );
    });

    testWidgets('el selector no deja elegir días pasados', (tester) async {
      await pump(tester, await create(deadline: march20), 'ana');

      await tester.tap(find.byKey(const Key('task.deadline.edit')));
      await tester.pumpAndSettle();

      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(picker.firstDate, DateTime(2026, 3, 14));
    });
  });
}
