// Flujo 1: descubrimiento y postulación a un proyecto.
//
// Ana entra, ve el proyecto en Descubrir, abre «Leer más», pulsa «¡Quiero
// colaborar!» y confirma. La app muestra «¡Listo!» y la solicitud queda
// pendiente. Nada de esto toca Roble: los datos salen de los dobles de
// `integration_test/support`.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:imker/core/utils/app_keys.dart';

import '../../support/fake_project_data_source.dart';
import '../../support/integration_harness.dart';
import '../../support/integration_seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationEnv env;

  group('Flujo 1: descubrir y aplicar a un proyecto', () {
    tearDown(Get.reset);

    testWidgets('Ana encuentra el proyecto y envía su postulación', (
      tester,
    ) => runFlow(tester, () async {
      env = await freshEnv(
        tester,
        () => setUpIntegrationEnv(
          user: Seed.ana,
          projects: [Seed.project()],
          members: [Seed.ownerMembership()],
        ),
      );
      await tester.pumpWidget(createHomeScreen());
      await logIn(tester, env);

      // Descubrir muestra el proyecto sembrado.
      await pumpUntilFound(tester, find.text(Seed.projectTitle));
      expect(find.text(Seed.projectTitle), findsOneWidget);

      // «Leer más» abre el detalle.
      await tapKey(tester, AppKeys.readMore(Seed.projectId));
      await pumpUntilFound(tester, find.text('Descripción'));
      await scrollTo(tester, find.byKey(AppKeys.applyToProject));

      // «¡Quiero colaborar!» pide confirmación.
      await tapKey(tester, AppKeys.applyToProject);
      await pumpUntilFound(tester, find.text('¿Postularte al proyecto?'));

      await tapKey(tester, AppKeys.confirmApplication);

      // Pantalla de confirmación.
      await pumpUntilFound(tester, find.text('¡Listo!'));
      expect(
        find.textContaining('será enviada al líder del proyecto'),
        findsOneWidget,
      );

      // Quedó guardada una solicitud pendiente de Ana a este proyecto...
      final requests = env.projects.joinRequestsOf(Seed.projectId);
      expect(requests, hasLength(1));
      expect(requests.single['user_id'], Seed.ana.id);
      expect(FakeProjectDataSource.stateOf(requests.single), 'pending');

      // ...y el proyecto quedó guardado para que aparezca en «Pendientes».
      expect(env.projects.saved.map((r) => r['project_id']), [Seed.projectId]);

      // Al volver, el detalle ya no ofrece postular.
      await tapKey(tester, AppKeys.operationDoneButton);
      await pumpUntilFound(
        tester,
        find.text('Postulación pendiente de respuesta'),
      );
      expect(find.text('¡Quiero colaborar!'), findsNothing);
    }));
  });
}
