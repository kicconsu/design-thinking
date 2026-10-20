import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/profile/ui/viewmodels/profile_controller.dart';
import 'package:imker/features/trust/domain/models/trust_metrics.dart';
import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

import '../../../../support/fake_trust_repository.dart';

class _Profiles implements IProfileRepository {
  @override
  Future<UserProfile> getMyProfile() async =>
      const UserProfile(program: 'Medicina');

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
  late ProfileController controller;

  setUp(() {
    Get.reset();
    trust = FakeTrustRepository();
    controller = ProfileController(
      _Profiles(),
      trust: trust,
      currentUserId: () => 'yo',
    );
  });

  tearDown(Get.reset);

  group('loadTrust', () {
    test('calcula los indicadores de quien tiene la sesión', () async {
      await controller.loadTrust();

      expect(trust.metricsAsked, ['yo']);
      expect(controller.trust.value?.commitment, 72);
      expect(controller.trustError.value, isNull);
      expect(controller.isLoadingTrust.value, isFalse);
    });

    test('profileWithTrust pone los indicadores en el perfil', () async {
      await controller.loadProfile();
      await controller.loadTrust();

      final profile = controller.profileWithTrust!;
      expect(profile.program, 'Medicina');
      expect(profile.hasTrustHistory, isTrue);
      expect(profile.commitmentScore, 72);
      expect(profile.onTimeScore, 80);
      expect(profile.fulfillmentScore, 65);
      expect(profile.completedProjectsScore, 50);
    });

    test('sin calcular, el perfil no trae indicadores ni ceros', () async {
      await controller.loadProfile();

      final profile = controller.profileWithTrust!;
      expect(profile.hasTrustHistory, isFalse);
      expect(profile.commitmentScore, isNull);
    });

    test('sin historial: hay perfil pero nada que mostrar', () async {
      trust.metrics = TrustMetrics.none;
      await controller.loadProfile();

      await controller.loadTrust();

      expect(controller.profileWithTrust!.hasTrustHistory, isFalse);
      expect(controller.profileWithTrust!.commitmentScore, isNull);
      expect(controller.trustError.value, isNull);
    });

    test('mientras calcula se ve cargando', () async {
      trust.gate = Completer<void>();

      final loading = controller.loadTrust();
      expect(controller.isLoadingTrust.value, isTrue);

      trust.gate!.complete();
      await loading;
      expect(controller.isLoadingTrust.value, isFalse);
    });
  });

  group('cuando falla', () {
    test('guarda el motivo y no deja ningún número', () async {
      trust.failure = const TrustFailure('Sin conexión. Verifica tu red.');

      await controller.loadTrust();

      expect(controller.trustError.value, 'Sin conexión. Verifica tu red.');
      expect(controller.trust.value, isNull);
      await controller.loadProfile();
      expect(controller.profileWithTrust!.commitmentScore, isNull);
      expect(controller.isLoadingTrust.value, isFalse);
    });

    test('reintentar lo corrige y limpia el error', () async {
      trust.failure = const TrustFailure('Sin conexión.');
      await controller.loadTrust();

      trust.failure = null;
      await controller.loadTrust();

      expect(controller.trustError.value, isNull);
      expect(controller.trust.value?.commitment, 72);
    });

    test(
      'si falla al recalcular, no se queda con los números viejos',
      () async {
        await controller.loadTrust();
        expect(controller.trust.value, isNotNull);

        trust.failure = const TrustFailure('Sin conexión.');
        await controller.loadTrust();

        expect(controller.trust.value, isNull);
        expect(controller.trustError.value, isNotNull);
      },
    );

    test('un error inesperado también se informa', () async {
      final broken = _Throwing();
      final c = ProfileController(
        _Profiles(),
        trust: broken,
        currentUserId: () => 'yo',
      );

      await c.loadTrust();

      expect(c.trustError.value, isNotNull);
      expect(c.trust.value, isNull);
    });
  });

  group('sesión', () {
    test('sin sesión no consulta nada', () async {
      final c = ProfileController(
        _Profiles(),
        trust: trust,
        currentUserId: () => '',
      );

      await c.loadTrust();

      expect(trust.metricsAsked, isEmpty);
      expect(c.trust.value, isNull);
    });

    test('sin repositorio de confianza no hace nada', () async {
      final c = ProfileController(_Profiles(), currentUserId: () => 'yo');

      await c.loadTrust();

      expect(c.trust.value, isNull);
      expect(c.trustError.value, isNull);
    });

    test('usa el repositorio registrado si no se le pasa uno', () async {
      Get.put<ITrustRepository>(trust);
      final c = ProfileController(_Profiles(), currentUserId: () => 'yo');

      await c.loadTrust();

      expect(c.trust.value?.commitment, 72);
    });

    test('clear() olvida los indicadores de quien se va', () async {
      await controller.loadTrust();

      controller.clear();

      expect(controller.trust.value, isNull);
      expect(controller.trustError.value, isNull);
      expect(controller.isLoadingTrust.value, isFalse);
    });

    test('un cálculo en vuelo de la sesión anterior se descarta', () async {
      trust.gate = Completer<void>();
      final loading = controller.loadTrust();

      controller.clear();
      trust.gate!.complete();
      await loading;

      expect(controller.trust.value, isNull);
      expect(controller.isLoadingTrust.value, isFalse);
    });
  });
}

class _Throwing extends FakeTrustRepository {
  @override
  Future<TrustMetrics> getTrustMetricsOf(String userId) async =>
      throw StateError('boom');
}
