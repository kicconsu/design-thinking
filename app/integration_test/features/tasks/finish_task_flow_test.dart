// Flujo 6: terminar una tarea que ya se tenía asignada.
//
// Laura tiene una tarea «En progreso» con dos de tres subtareas hechas.
// Marca la última y guarda: la tarea pasa a «Terminadas» y el progreso del
// proyecto sube a 100 %.
// Nada de esto toca Roble: los datos salen de los dobles de `integration_test/support`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../support/integration_harness.dart';
import '../../support/integration_seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const taskId = 'tarea-informe';
  const taskTitle = 'Redactar informe';

  late IntegrationEnv env;

  group('Flujo 6: terminar tarea asignada', () {
    tearDown(Get.reset);

    testWidgets('Laura marca la última subtarea y la tarea queda terminada', (
      tester,
    ) => runFlow(tester, () async {
      env = await freshEnv(
        tester,
        () => setUpIntegrationEnv(
          user: Seed.laura,
          projects: [Seed.project()],
          members: [Seed.ownerMembership()],
          taskStays: [Seed.taskStay(taken: 1)],
          tasks: [
            Seed.task(
              id: taskId,
              title: taskTitle,
              status: 'doing',
              assignee: Seed.laura.id,
              checklist: [
                Seed.item('Reunir datos', done: true),
                Seed.item('Escribir borrador', done: true),
                Seed.item('Revisar y entregar'),
              ],
            ),
          ],
        ),
      );
      await tester.pumpWidget(createHomeScreen());
      await logIn(tester, env);

      await openMyProjects(tester);
      await openProjectInfo(tester, Seed.projectTitle);
      await openTaskBoard(tester);

      // Está «En progreso» y es suya.
      await tapText(tester, 'En Progreso');
      await pumpUntilFound(tester, find.text('Reservada por Tú'));
      await tapText(tester, taskTitle);
      await pumpUntilFound(tester, find.text('Progreso de tarea'));

      // Marca la subtarea que faltaba y guarda.
      await tapOn(
        tester,
        find.widgetWithText(CheckboxListTile, 'Revisar y entregar'),
      );
      await tapText(tester, 'Guardar');
      await pumpUntil(
        tester,
        () => env.tasks.taskRow(taskId)!['status'] == 'done',
        'la tarea pasó a terminada',
      );

      // La tarea quedó terminada, con hora de cierre.
      final saved = env.tasks.taskRow(taskId)!;
      expect((saved['checklist'] as List).every((e) => e['done'] == true), isTrue);
      expect(saved['status'], 'done');
      expect(saved['finished_at'], isNotNull);

      // El proyecto y la persona quedaron al día.
      expect(env.tasks.progressByProject[Seed.projectId], 100);
      expect(
        env.tasks.memberRow(Seed.projectId, Seed.laura.id)!['tasks_finished'],
        1,
      );

      // En el gabinete la tarea aparece en «Terminadas».
      await goBack(tester);
      await tapText(tester, 'Terminadas');
      await pumpUntilFound(tester, find.text(taskTitle));
      expect(find.text('Todavía no hay tareas terminadas.'), findsNothing);

      // Y la pestaña «Progreso» del proyecto marca 100 %.
      await goBack(tester);
      await pumpUntilFound(tester, find.byKey(const ValueKey('progress-percent')));
      await pumpUntilFound(tester, find.text('100%'));
    }));
  });
}
