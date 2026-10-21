import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/subtask.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/pages/task_progress_page.dart';
import 'package:imker/core/utils/app_keys.dart';

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

  group('TaskProgressPage', () {
    Future<void> pump(
      WidgetTester tester,
      ProjectTask task,
      String user,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: TaskProgressPage(
            project: DummyData.kircheProject,
            task: task,
            currentUserId: () => user,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('quien la reservó añade subtareas, las marca y guarda', (
      tester,
    ) async {
      final task = await reserved('ana');
      await pump(tester, task, 'ana');

      await tester.enterText(find.byType(TextField).at(1), 'Implementar GET');
      await tester.ensureVisible(find.byKey(AppKeys.checklistAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.checklistAdd));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.saveProgress));
      await tester.pumpAndSettle();

      final stored = (await repo.getTasks(projectId)).single;
      expect(stored.subtasks, const [
        Subtask(title: 'Implementar GET', done: true),
      ]);
      expect(stored.status, TaskStatus.done);
      expect(find.textContaining('pasó a "Terminadas"'), findsOneWidget);

      // El aviso deja un temporizador de 3 s.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('otro miembro la ve de solo lectura, sin Guardar', (
      tester,
    ) async {
      final task = await reserved('ana');
      await pump(tester, task, 'luis');

      expect(find.byKey(AppKeys.saveProgress), findsNothing);
      expect(find.byKey(AppKeys.checklistAdd), findsNothing);
      expect(
        find.text('Solo quien reservó la tarea puede editarla.'),
        findsOneWidget,
      );
    });

    testWidgets('la pestaña Comentarios lista y publica', (tester) async {
      final task = await reserved('ana');
      await repo.addComment(task: task, userId: 'ana', body: 'Ya empecé');
      await pump(tester, task, 'ana');

      await tester.tap(find.text('Comentarios'));
      await tester.pumpAndSettle();
      expect(find.text('Ya empecé'), findsOneWidget);
      expect(find.text('1 comentario'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Listo el GET');
      await tester.tap(find.text('Comentar'));
      await tester.pumpAndSettle();

      expect(find.text('Listo el GET'), findsOneWidget);
      expect(find.text('2 comentarios'), findsOneWidget);
    });
  });
}
