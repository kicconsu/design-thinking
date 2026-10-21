// Flujo 3: ver una solicitud de colaboración y rechazarla.
//
// Laura lidera el proyecto y Bruno tiene una solicitud pendiente. Laura la
// abre y la rechaza. Bruno no entra al proyecto.
// Nada de esto toca Roble: los datos salen de los dobles de `integration_test/support`.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../support/fake_project_data_source.dart';
import '../../support/integration_harness.dart';
import '../../support/integration_seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationEnv env;

  group('Flujo 3: ver solicitud y rechazar', () {
    tearDown(Get.reset);

    testWidgets('Laura rechaza la solicitud de Bruno', (tester) => runFlow(tester, () async {
      env = await freshEnv(
        tester,
        () => setUpIntegrationEnv(
          user: Seed.laura,
          projects: [Seed.project()],
          members: [Seed.ownerMembership()],
          joinRequests: [Seed.pendingRequest()],
        ),
      );
      await tester.pumpWidget(createHomeScreen());
      await logIn(tester, env);

      await openMyProjects(tester);
      await pumpUntilFound(tester, find.text('1 solicitud'));

      await tapText(tester, '1 solicitud');
      await pumpUntilFound(tester, find.text('Solicitudes de colaboración'));
      await pumpUntilFound(tester, find.text(Seed.bruno.name));

      await tapText(tester, Seed.bruno.name);
      await pumpUntilFound(tester, find.text('Rechazar'));

      await tapText(tester, 'Rechazar');
      await pumpUntilFound(tester, find.text('Solicitud rechazada'));

      // La solicitud quedó rechazada por Laura y Bruno no es miembro.
      final request = env.projects.joinRequestsOf(Seed.projectId).single;
      expect(FakeProjectDataSource.stateOf(request), 'rejected');
      expect(request['reviewed_by'], Seed.laura.id);
      expect(env.projects.activeMemberIds(Seed.projectId), {Seed.laura.id});

      // Al volver, la solicitud ya no está en la lista.
      await tapText(tester, 'Ver más solicitudes');
      await pumpUntilFound(
        tester,
        find.text('No hay solicitudes pendientes por revisar.'),
      );
      // La pantalla de detalle se cierra con una animación: se espera a que
      // termine antes de comprobar que Bruno ya no está.
      await pumpUntilGone(tester, find.text(Seed.bruno.name));
      expect(find.text(Seed.bruno.name), findsNothing);
    }));
  });
}
