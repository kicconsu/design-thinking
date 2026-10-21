import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/trust_indicators.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/ui/pages/trust_indicators_page.dart';
import 'package:imker/features/profile/ui/viewmodels/profile_controller.dart';
import 'package:imker/features/profile/ui/widgets/profile_view.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

import '../../../../support/fake_trust_repository.dart';
import '../../../../support/fake_profile_repository.dart';

const _base = UserProfile(
  program: 'Ingeniería de Sistemas',
  skills: ['Python'],
);

Widget _host(Widget child) => GetMaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('ProfileView · indicadores de confianza', () {
    testWidgets('mientras se calculan muestra la carga, no números', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ProfileView(
            name: 'Ana',
            profile: _base,
            isOwn: true,
            trustLoading: true,
          ),
        ),
      );

      expect(find.byKey(const Key('profile.trust.loading')), findsOneWidget);
      expect(find.byType(TrustIndicators), findsNothing);
      expect(find.textContaining('Aparecen'), findsNothing);
    });

    testWidgets(
      'si fallan, el error manda sobre la carga: motivo y Reintentar',
      (tester) async {
        var retried = 0;
        await tester.pumpWidget(
          _host(
            ProfileView(
              name: 'Ana',
              profile: _base,
              isOwn: true,
              trustLoading: true,
              trustError: 'No pudimos calcular los indicadores.',
              onRetryTrust: () => retried++,
            ),
          ),
        );

        expect(
          find.text('No pudimos calcular los indicadores.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('profile.trust.loading')), findsNothing);
        expect(find.byType(TrustIndicators), findsNothing);
        expect(find.text('0%'), findsNothing);

        final retry = find.byKey(const Key('profile.trust.retry'));
        await tester.ensureVisible(retry);
        await tester.tap(retry);
        expect(retried, 1);
      },
    );

    testWidgets('sin historial sigue diciendo cuándo aparecerán', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const ProfileView(name: 'Ana', profile: _base, isOwn: true)),
      );

      expect(find.textContaining('Aparecen cuando colabores'), findsOneWidget);
    });
  });

  group('OwnTrustIndicatorsPage', () {
    late FakeTrustRepository trust;
    late ProfileController controller;

    setUp(() {
      Get.reset();
      trust = FakeTrustRepository();
      controller = ProfileController(
        FakeProfileRepository(me: _base, other: _base),
        trust: trust,
        currentUserId: () => 'yo',
      );
      Get.put(controller);
    });

    tearDown(Get.reset);

    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: OwnTrustIndicatorsPage()),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('si fallan, ofrece reintentar y al lograrlo los muestra', (
      tester,
    ) async {
      await controller.loadProfile();
      trust.failure = const TrustFailure('Sin conexión.');
      await controller.loadTrust();
      await open(tester);

      expect(find.text('Sin conexión.'), findsOneWidget);
      expect(find.byType(TrustIndicators), findsNothing);

      trust.failure = null;
      await tester.tap(find.byKey(const Key('trust.page.retry')));
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión.'), findsNothing);
      expect(find.byType(TrustIndicators), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
    });
  });
}
