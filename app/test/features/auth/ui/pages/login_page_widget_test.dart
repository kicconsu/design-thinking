import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/core/utils/app_keys.dart';
import 'package:imker/features/auth/ui/pages/login_page.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

import '../../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;
  late AuthenticationController auth;

  /// La pantalla de login con las dos rutas a las que puede ir.
  Future<void> pumpLogin(WidgetTester tester) async {
    auth = Get.put(AuthenticationController(repo));
    await tester.pumpWidget(
      GetMaterialApp(
        home: const LoginPage(),
        getPages: [
          GetPage(name: AppRoutes.home, page: () => const Text('INICIO')),
          GetPage(name: AppRoutes.register, page: () => const Text('REGISTRO')),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.byKey(AppKeys.loginEmail), email);
    await tester.enterText(find.byKey(AppKeys.loginPassword), password);
  }

  setUp(() {
    Get.reset();
    repo = FakeAuthRepository();
  });

  tearDown(Get.reset);

  group('validación del formulario', () {
    testWidgets('con los campos vacíos avisa y no llama al servidor', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.tap(find.byKey(AppKeys.loginSubmit));
      await tester.pump();

      expect(find.text('Correo inválido'), findsOneWidget);
      expect(find.text('Mínimo 7 caracteres'), findsOneWidget);
      expect(repo.calls, isNot(contains('login')));
    });

    testWidgets('una contraseña corta no pasa', (tester) async {
      await pumpLogin(tester);

      await fill(tester, 'ana@uninorte.edu.co', '123456');
      await tester.tap(find.byKey(AppKeys.loginSubmit));
      await tester.pump();

      expect(find.text('Mínimo 7 caracteres'), findsOneWidget);
      expect(find.text('Correo inválido'), findsNothing);
      expect(repo.calls, isNot(contains('login')));
    });
  });

  group('entrar', () {
    testWidgets('con datos válidos entra y pasa al inicio', (tester) async {
      await pumpLogin(tester);

      await fill(tester, '  ana@uninorte.edu.co ', 'secreta1');
      await tester.tap(find.byKey(AppKeys.loginSubmit));
      await tester.pumpAndSettle();

      expect(repo.lastLogin!.email, 'ana@uninorte.edu.co');
      expect(find.text('INICIO'), findsOneWidget);
    });

    testWidgets('si el servidor lo rechaza, avisa y se queda', (tester) async {
      repo.loginResult = false;
      await pumpLogin(tester);

      await fill(tester, 'ana@uninorte.edu.co', 'secreta1');
      await tester.tap(find.byKey(AppKeys.loginSubmit));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo iniciar sesión'), findsWidgets);
      expect(find.text('INICIO'), findsNothing);
      expect(find.byKey(AppKeys.loginSubmit), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('mientras entra muestra una espera en vez del botón', (
      tester,
    ) async {
      repo.loginGate = Completer<void>();
      await pumpLogin(tester);

      final pending = auth.login('ana@uninorte.edu.co', 'secreta1');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(AppKeys.loginSubmit), findsNothing);

      repo.loginGate!.complete();
      await pending;
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.loginSubmit), findsOneWidget);
    });

    testWidgets('el error de la sesión caída se ve en la pantalla', (
      tester,
    ) async {
      await pumpLogin(tester);

      auth.error.value = 'Tu sesión caducó. Vuelve a entrar.';
      await tester.pump();

      expect(find.text('Tu sesión caducó. Vuelve a entrar.'), findsOneWidget);
    });
  });

  group('otras salidas', () {
    testWidgets('«Entrar como invitado» abre sesión anónima y pasa al inicio', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Entrar como invitado'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('signInAnonymously'));
      expect(auth.isAnonymous, isTrue);
      expect(find.text('INICIO'), findsOneWidget);
    });

    testWidgets('«Crear cuenta» lleva al registro', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('REGISTRO'), findsOneWidget);
    });

    testWidgets('sin DEV_LOGIN no hay acceso rápido de desarrollo', (
      tester,
    ) async {
      await pumpLogin(tester);

      expect(find.text('Acceso rápido Dev'), findsNothing);
    });
  });
}
