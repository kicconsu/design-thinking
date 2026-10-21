import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/auth/ui/pages/register_page.dart';
import 'package:imker/features/auth/ui/pages/upgrade_account_page.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';

import '../../../../support/fake_auth_repository.dart';

/// Pantalla baja y bajo el teclado: lo que queda libre no alcanza para los tres
/// campos y el botón, y no debe haber desbordamiento.
void main() {
  setUp(() => Get.put(AuthenticationController(FakeAuthRepository())));
  tearDown(Get.reset);

  for (final entry in {
    'Completa tu cuenta': const UpgradeAccountPage(),
    'Crear cuenta': const RegisterPage(),
  }.entries) {
    testWidgets('${entry.key} no se desborda con el teclado abierto', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 900);
      tester.view.devicePixelRatio = 2.5;
      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(GetMaterialApp(home: entry.value));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
