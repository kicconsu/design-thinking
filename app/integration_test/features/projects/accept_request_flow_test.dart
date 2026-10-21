// Flujo 2: ver una solicitud de colaboración y aceptarla.
//
// Laura lidera el proyecto y Bruno tiene una solicitud pendiente. Laura abre
// sus solicitudes, revisa la de Bruno y la acepta. Bruno pasa a ser miembro.
// Nada de esto toca Roble: los datos salen de los dobles de `integration_test/support`.

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

  group('Flujo 2: ver solicitud y aceptar', () {
    tearDown(Get.reset);

    testWidgets('Laura acepta la solicitud de Bruno', (tester) => runFlow(tester, () async {
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

      // «Mis proyectos» avisa que hay una solicitud pendiente.
      await openMyProjects(tester);
      await pumpUntilFound(tester, find.text('1 solicitud'));

      // La lista de solicitudes muestra a Bruno.
      await tapText(tester, '1 solicitud');
      await pumpUntilFound(tester, find.text('Solicitudes de colaboración'));
      await pumpUntilFound(tester, find.text(Seed.bruno.name));

      // Su ficha trae las acciones de decidir.
      await tapText(tester, Seed.bruno.name);
      await pumpUntilFound(tester, find.text('Aceptar solicitud'));
      expect(find.text('Rechazar'), findsOneWidget);

      await tapKey(tester, AppKeys.requestAccept);
      await pumpUntilFound(tester, find.text('Solicitud aceptada'));

      // La solicitud quedó aceptada por Laura y Bruno es miembro.
      final request = env.projects.joinRequestsOf(Seed.projectId).single;
      expect(FakeProjectDataSource.stateOf(request), 'accepted');
      expect(request['reviewed_by'], Seed.laura.id);
      expect(
        env.projects.activeMemberIds(Seed.projectId),
        containsAll([Seed.laura.id, Seed.bruno.id]),
      );

      // Al volver, la solicitud ya no está en la lista.
      await tapKey(tester, AppKeys.requestMore);
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
