// Flujo 5: asignarse una tarea y dejar un progreso parcial.
//
// El proyecto ya tiene una tarea pendiente con tres subtareas. Laura la
// reserva, marca una subtarea y guarda. La tarea sigue «En progreso».
// Nada de esto toca Roble: los datos salen de los dobles de `integration_test/support`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:imker/core/utils/app_keys.dart';

import '../../support/integration_harness.dart';
import '../../support/integration_seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const taskId = 'tarea-prototipo';
  const taskTitle = 'Diseñar prototipo';

  late IntegrationEnv env;

  group('Flujo 5: asignarse tarea y avanzar parcialmente', () {
    tearDown(Get.reset);

    testWidgets('Laura reserva la tarea y marca una subtarea', (tester) => runFlow(tester, () async {
      env = await freshEnv(
        tester,
        () => setUpIntegrationEnv(
          user: Seed.laura,
          projects: [Seed.project()],
          members: [Seed.ownerMembership()],
          taskStays: [Seed.taskStay()],
          tasks: [
            Seed.task(
              id: taskId,
              title: taskTitle,
              checklist: [
                Seed.item('Definir wireframes'),
                Seed.item('Diseñar pantallas'),
                Seed.item('Validar con usuarios'),
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

      // La tarea está en «Pendientes», sin responsable.
      await pumpUntilFound(tester, find.text(taskTitle));
      expect(env.tasks.taskRow(taskId)!['assignee_id'], isNull);

      // Reservarla.
      await tapReserveTask(tester);
      await pumpUntil(
        tester,
        () => env.tasks.taskRow(taskId)!['assignee_id'] == Seed.laura.id,
        'la tarea quedó reservada por Laura',
      );
      expect(env.tasks.taskRow(taskId)!['assignee_id'], Seed.laura.id);
      expect(env.tasks.taskRow(taskId)!['status'], 'doing');
      expect(
        env.tasks.memberRow(Seed.projectId, Seed.laura.id)!['tasks_taken'],
        1,
      );

      // Aparece en «En progreso», reservada por ella.
      await tapKey(tester, AppKeys.taskBoardTab(1));
      await pumpUntilFound(tester, find.text('Reservada por Tú'));
      await tapText(tester, taskTitle);
      await pumpUntilFound(tester, find.text('Progreso de tarea'));

      // Marca solo la primera subtarea y guarda.
      await tapOn(
        tester,
        find.widgetWithText(CheckboxListTile, 'Definir wireframes'),
      );
      await tapKey(tester, AppKeys.saveProgress);
      await pumpUntil(
        tester,
        () => (env.tasks.taskRow(taskId)!['checklist'] as List).any(
          (e) => e['done'] == true,
        ),
        'el checklist quedó guardado con una subtarea hecha',
      );

      // Progreso parcial: una de tres hecha y la tarea sigue en progreso.
      final saved = env.tasks.taskRow(taskId)!;
      final checklist = saved['checklist'] as List;
      expect(checklist.map((e) => e['done']), [true, false, false]);
      expect(saved['status'], 'doing');
      expect(saved['finished_at'], isNull);
    }));
  });
}
