// Flujo 4: crear una tarea con algunas subtareas.
//
// Laura abre el gabinete de su proyecto, crea una tarea, la reserva y le
// agrega tres subtareas en el checklist (solo quien reserva una tarea puede
// editarla). Nada de esto toca Roble: los datos salen de los dobles de
// `integration_test/support`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../support/integration_harness.dart';
import '../../support/integration_seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const taskTitle = 'Diseñar prototipo';
  const subtasks = [
    'Definir wireframes',
    'Diseñar pantallas',
    'Validar con usuarios',
  ];

  late IntegrationEnv env;

  group('Flujo 4: crear tarea con subtareas', () {
    tearDown(Get.reset);

    testWidgets('Laura crea una tarea y le agrega tres subtareas', (
      tester,
    ) => runFlow(tester, () async {
      env = await freshEnv(
        tester,
        () => setUpIntegrationEnv(
          user: Seed.laura,
          projects: [Seed.project()],
          members: [Seed.ownerMembership()],
          taskStays: [Seed.taskStay()],
        ),
      );
      await tester.pumpWidget(createHomeScreen());
      await logIn(tester, env);

      await openMyProjects(tester);
      await openProjectInfo(tester, Seed.projectTitle);
      await openTaskBoard(tester);
      expect(find.text('No hay tareas pendientes.'), findsOneWidget);

      // Crear la tarea desde el diálogo.
      await tapText(tester, 'Crear tarea');
      await pumpUntilFound(tester, find.byKey(const Key('task.new.title')));
      await tester.enterText(
        find.byKey(const Key('task.new.title')),
        taskTitle,
      );
      await tester.enterText(
        find.byKey(const Key('task.new.description')),
        'Pantallas principales de la app',
      );
      await tester.pump();
      await tapOn(tester, find.widgetWithText(FilledButton, 'Crear'));

      // Aparece en «Pendientes» y quedó guardada sin responsable.
      await pumpUntilFound(tester, find.text(taskTitle));
      final created = env.tasks.taskByTitle(Seed.projectId, taskTitle);
      expect(created, isNotNull);
      expect(created!['status'], 'todo');
      expect(created['assignee_id'], isNull);
      expect(env.tasks.totalTasksByProject[Seed.projectId], 1);

      // Reservarla: pasa a «En progreso» y es de Laura.
      await tapText(tester, 'Reservar tarea');
      await pumpUntil(
        tester,
        () =>
            env.tasks.taskRow(created['_id'] as String)!['assignee_id'] ==
            Seed.laura.id,
        'la tarea quedó reservada por Laura',
      );
      expect(env.tasks.taskRow(created['_id'] as String)!['assignee_id'], Seed.laura.id);
      expect(
        env.tasks.memberRow(Seed.projectId, Seed.laura.id)!['tasks_taken'],
        1,
      );

      await tapText(tester, 'En Progreso');
      await pumpUntilFound(tester, find.text('Reservada por Tú'));
      await tapText(tester, taskTitle);
      await pumpUntilFound(tester, find.text('Progreso de tarea'));

      // Agregar las tres subtareas al checklist.
      final newSubtask = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Escribe una subtarea',
      );
      for (final title in subtasks) {
        // Se escribe directo en el controlador del campo: es lo que lee
        // «Añadir», y evita depender del teclado del navegador.
        tester.widget<TextField>(newSubtask).controller!.text = title;
        await tester.pump();
        await tapText(tester, 'Añadir');
        await pumpUntilFound(tester, find.text(title));
      }

      await tapText(tester, 'Guardar');
      await pumpUntil(
        tester,
        () =>
            (env.tasks.taskRow(created['_id'] as String)!['checklist'] as List)
                .length ==
            subtasks.length,
        'el checklist quedó guardado con las tres subtareas',
      );

      // La tarea quedó con las tres subtareas, todas pendientes.
      final saved = env.tasks.taskRow(created['_id'] as String)!;
      final checklist = saved['checklist'] as List;
      expect(checklist.map((e) => e['title']), subtasks);
      expect(checklist.every((e) => e['done'] == false), isTrue);
      expect(saved['status'], 'doing');
    }));
  });
}
