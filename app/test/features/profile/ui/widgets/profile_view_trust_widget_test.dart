import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/trust_indicators.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/ui/pages/trust_indicators_page.dart';
import 'package:imker/features/profile/ui/viewmodels/profile_controller.dart';
import 'package:imker/features/profile/ui/widgets/profile_view.dart';
import 'package:imker/features/trust/domain/models/trust_metrics.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

import '../../../../support/fake_trust_repository.dart';
import '../../../../support/fake_profile_repository.dart';

const _base = UserProfile(
  program: 'Ingeniería de Sistemas',
  skills: ['Python'],
);

const _withTrust = UserProfile(
  program: 'Ingeniería de Sistemas',
  skills: ['Python'],
  hasTrustHistory: true,
  commitmentScore: 72,
  onTimeScore: null,
  fulfillmentScore: 65,
  completedProjectsScore: 50,
);

Widget _host(Widget child) => GetMaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('ProfileView · indicadores de confianza', () {
    testWidgets('con indicadores los muestra, y «—» donde no hay datos', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const ProfileView(name: 'Ana', profile: _withTrust, isOwn: true)),
      );

      expect(find.byType(TrustIndicators), findsOneWidget);
      expect(find.text('Cumplimiento'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('—'), findsOneWidget); // entrega a tiempo sin datos
    });

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

    testWidgets('si fallan, muestra el motivo y Reintentar, no ceros', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        _host(
          ProfileView(
            name: 'Ana',
            profile: _base,
            isOwn: true,
            trustError: 'No pudimos calcular los indicadores.',
            onRetryTrust: () => retried++,
          ),
        ),
      );

      expect(find.text('No pudimos calcular los indicadores.'), findsOneWidget);
      expect(find.byType(TrustIndicators), findsNothing);
      expect(find.text('0%'), findsNothing);

      final retry = find.byKey(const Key('profile.trust.retry'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      expect(retried, 1);
    });

    testWidgets('el error manda sobre la carga', (tester) async {
      await tester.pumpWidget(
        _host(
          const ProfileView(
            name: 'Ana',
            profile: _base,
            isOwn: true,
            trustLoading: true,
            trustError: 'Sin conexión.',
          ),
        ),
      );

      expect(find.byKey(const Key('profile.trust.error')), findsOneWidget);
      expect(find.byKey(const Key('profile.trust.loading')), findsNothing);
    });

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

    testWidgets('muestra mis indicadores calculados', (tester) async {
      await controller.loadProfile();
      await controller.loadTrust();
      await open(tester);

      expect(find.byType(TrustIndicators), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      // El medidor y su explicación.
      expect(find.text('Cumplimiento'), findsNWidgets(2));
    });

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
    });

    testWidgets('sin historial dice que todavía no hay indicadores', (
      tester,
    ) async {
      trust.metrics = TrustMetrics.none;
      await controller.loadProfile();
      await controller.loadTrust();
      await open(tester);

      expect(find.text('Todavía no hay indicadores'), findsOneWidget);
      expect(
        find.text('Aparecen cuando colabores en un proyecto.'),
        findsOneWidget,
      );
      expect(find.textContaining('tasa de respuesta'), findsNothing);
    });
  });
}
