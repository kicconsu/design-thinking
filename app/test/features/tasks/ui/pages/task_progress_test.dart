import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/project_task.dart';
import 'package:imker/features/tasks/domain/models/subtask.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/tasks/ui/pages/task_progress_page.dart';
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
      'completar el checklist termina la tarea y sube el progreso',
      () async {
        final task = await reserved('ana');

        final saved = await repo.saveTaskProgress(
          task: task,
          description: '',
          subtasks: const [Subtask(title: 'GET', done: true)],
        );

        expect(saved.status, TaskStatus.done);
        expect(source.progressByProject[projectId], 100);
      },
    );

    test('desmarcar una terminada baja el progreso otra vez', () async {
      final task = await reserved('ana');
      final done = await repo.saveTaskProgress(
        task: task,
        description: '',
        subtasks: const [Subtask(title: 'GET', done: true)],
      );

      final back = await repo.saveTaskProgress(
        task: done,
        description: '',
        subtasks: const [Subtask(title: 'GET')],
      );

      expect(back.status, TaskStatus.doing);
      expect(source.progressByProject[projectId], 0);
    });

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
      await tester.ensureVisible(find.text('Añadir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
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

      expect(find.text('Guardar'), findsNothing);
      expect(find.text('Añadir'), findsNothing);
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
