import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/ui/pages/onboarding_page.dart';
import 'package:imker/features/profile/ui/viewmodels/profile_controller.dart';
import 'package:imker/routes/app_routes.dart';

import '../../../../support/fake_profile_repository.dart';
import '../../../../support/fake_auth_repository.dart';

Widget _app({Object? arguments}) => GetMaterialApp(
  initialRoute: '/start',
  getPages: [
    GetPage(
      name: '/start',
      page: () => Builder(
        builder: (context) {
          // Entra a /onboarding como lo hace el registro.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => Get.offNamed(AppRoutes.onboarding, arguments: arguments),
          );
          return const SizedBox();
        },
      ),
    ),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingPage()),
    GetPage(
      name: AppRoutes.home,
      page: () => const Scaffold(body: Text('HOME')),
    ),
  ],
);

void main() {
  late FakeProfileRepository profiles;

  setUp(() {
    profiles = FakeProfileRepository(other: const UserProfile());
    Get.put(AuthenticationController(FakeAuthRepository()));
    Get.put(ProfileController(profiles));
  });

  tearDown(Get.reset);

  Future<void> open(WidgetTester tester, {Object? arguments}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(arguments: arguments));
    await tester.pumpAndSettle();
  }

  testWidgets('guardar envía lo escrito y entra a Home', (tester) async {
    await open(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'p. ej. Ingeniería de Sistemas'),
      'Medicina',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Escribe una habilidad'),
      'Anatomía',
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar y continuar'));
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(profiles.saved.single.program, 'Medicina');
    expect(profiles.saved.single.skills, ['Anatomía']);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('«Ahora no» entra a Home sin escribir nada', (tester) async {
    await open(tester);

    await tester.ensureVisible(find.text('Ahora no'));
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(profiles.saved, isEmpty);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('guardar con todo vacío equivale a omitir', (tester) async {
    await open(tester);

    await tester.ensureVisible(find.text('Guardar y continuar'));
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(profiles.saved, isEmpty);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('si falla el guardado se queda y muestra el error', (
    tester,
  ) async {
    profiles.failure = const ProfileFailure('Sin conexión. Verifica tu red.');
    await open(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'p. ej. Ingeniería de Sistemas'),
      'Medicina',
    );
    await tester.ensureVisible(find.text('Guardar y continuar'));
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsNothing);
    expect(find.text('Sin conexión. Verifica tu red.'), findsOneWidget);

    // Deja que el aviso termine para no dejar temporizadores pendientes.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('un invitado que sube de cuenta vuelve a la pestaña Perfil', (
    tester,
  ) async {
    final home = Get.put(HomeViewModel());
    await open(tester, arguments: const OnboardingArgs(homeTab: 2));

    await tester.ensureVisible(find.text('Ahora no'));
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(home.currentIndex.value, 2);
  });

  testWidgets(
    'tras registrarse se abre en Descubrir aunque quedara otra pestaña',
    (tester) async {
      final home = Get.put(HomeViewModel())..changePage(2);
      await open(tester);

      await tester.ensureVisible(find.text('Ahora no'));
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      expect(home.currentIndex.value, 0);
    },
  );
}
