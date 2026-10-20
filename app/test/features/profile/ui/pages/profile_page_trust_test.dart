import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/trust_indicators.dart';
import 'package:imker/features/auth/domain/models/authentication_user.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/profile/ui/pages/profile_page.dart';
import 'package:imker/features/profile/ui/viewmodels/profile_controller.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/trust/domain/models/trust_metrics.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

import '../../../../support/fake_trust_repository.dart';

class _Auth implements IAuthRepository {
  @override
  Future<bool> restoreSession() async => true;

  @override
  Future<AuthenticationUser?> getLoggedUser() async => AuthenticationUser(
    id: 'yo',
    email: 'yo@correo.com',
    name: 'Valentina Ríos',
    password: '',
  );

  @override
  bool get isAnonymous => false;

  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles implements IProfileRepository {
  @override
  Future<UserProfile> getMyProfile() async =>
      const UserProfile(program: 'Ingeniería de Sistemas', skills: ['Python']);

  @override
  Future<UserProfile> getProfileOf(String userId) async => const UserProfile();

  @override
  Future<void> ensureMyProfile({required String name}) async {}

  @override
  Future<UserProfile> updateMyProfile({
    required String program,
    required String institution,
    required String bio,
    required List<String> skills,
  }) async => const UserProfile();
}

void main() {
  late FakeTrustRepository trust;

  setUp(() {
    Get.reset();
    trust = FakeTrustRepository();
    Get.put<IProfileRepository>(_Profiles());
    Get.put<IProjectRepository>(ProjectRepository(InMemoryProjectDataSource()));
    Get.put(UserProjectsController(currentUserId: () => 'yo'));
    Get.put(
      ProfileController(
        Get.find<IProfileRepository>(),
        trust: trust,
        currentUserId: () => 'yo',
      ),
    );
  });

  tearDown(Get.reset);

  /// Una pantalla alta para que el perfil entero quepa sin desplazarse.
  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openProfile(WidgetTester tester) async {
    tallScreen(tester);
    Get.put(AuthenticationController(_Auth()));
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: ProfilePage())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('al entrar calcula y muestra mis indicadores', (tester) async {
    await openProfile(tester);

    expect(trust.metricsAsked, ['yo']);
    expect(find.byType(TrustIndicators), findsOneWidget);
    expect(find.text('72%'), findsWidgets);
    expect(find.text('Cumplimiento'), findsOneWidget);
  });

  testWidgets('mientras calcula muestra la carga, sin números', (tester) async {
    tallScreen(tester);
    trust.gate = Completer<void>();
    Get.put(AuthenticationController(_Auth()));
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: ProfilePage())),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('profile.trust.loading')), findsOneWidget);
    expect(find.byType(TrustIndicators), findsNothing);

    trust.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TrustIndicators), findsOneWidget);
  });

  testWidgets('si falla, dice por qué y Reintentar los trae', (tester) async {
    trust.failure = const TrustFailure('Sin conexión. Verifica tu red.');
    await openProfile(tester);

    expect(find.text('Sin conexión. Verifica tu red.'), findsOneWidget);
    expect(find.byType(TrustIndicators), findsNothing);
    expect(find.text('0%'), findsNothing);

    trust.failure = null;
    await tester.tap(find.byKey(const Key('profile.trust.retry')));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión. Verifica tu red.'), findsNothing);
    expect(find.byType(TrustIndicators), findsOneWidget);
  });

  testWidgets('jalar para refrescar recalcula los indicadores', (tester) async {
    await openProfile(tester);
    expect(trust.metricsAsked, hasLength(1));

    trust.metrics = const TrustMetrics(
      commitment: 90,
      onTime: 90,
      fulfillment: 90,
      completedProjects: 90,
      hasHistory: true,
    );
    // Es lo que hace el gesto de jalar hacia abajo.
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    await tester.pumpAndSettle();

    expect(trust.metricsAsked, hasLength(2));
    expect(find.text('90%'), findsWidgets);
  });
}
