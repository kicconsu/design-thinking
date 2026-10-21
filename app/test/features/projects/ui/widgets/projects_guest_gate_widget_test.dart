import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/projects/ui/widgets/projects_guest_gate.dart';
import 'package:imker/routes/app_routes.dart';

import '../../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;

  /// La pantalla con el control de invitado y las rutas a las que puede ir.
  Future<AuthenticationController> pumpGate(
    WidgetTester tester, {
    required bool guest,
  }) async {
    final auth = Get.put(AuthenticationController(repo));
    await tester.pump();
    if (guest) await auth.signInAsGuest();
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: ProjectsGuestGate()),
        getPages: [
          GetPage(name: AppRoutes.login, page: () => const Text('LOGIN')),
          GetPage(
            name: AppRoutes.upgradeAccount,
            page: () => const Text('COMPLETAR'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  setUp(() {
    Get.reset();
    repo = FakeAuthRepository();
  });

  tearDown(Get.reset);

  testWidgets('explica qué se gana con una cuenta', (tester) async {
    await pumpGate(tester, guest: true);

    expect(find.text('Tus proyectos y colaboraciones'), findsOneWidget);
    expect(find.textContaining('completa tu cuenta'), findsOneWidget);
  });

  testWidgets('un invitado ve «Completar mi cuenta» y va a completarla', (
    tester,
  ) async {
    await pumpGate(tester, guest: true);

    await tester.tap(find.text('Completar mi cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('COMPLETAR'), findsOneWidget);
  });

  testWidgets('quien no ha entrado ve «Iniciar sesión» y va al login', (
    tester,
  ) async {
    await pumpGate(tester, guest: false);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
  });
}
