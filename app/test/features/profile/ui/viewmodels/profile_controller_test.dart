import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/ui/viewmodels/profile_controller.dart';

import '../../../../support/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repo;
  late ProfileController controller;

  setUp(() {
    repo = FakeProfileRepository(
      me: const UserProfile(program: 'Medicina'),
      other: const UserProfile(),
    );
    controller = ProfileController(repo);
  });

  test('loadProfile guarda el perfil leído', () async {
    await controller.loadProfile();

    expect(controller.profile?.program, 'Medicina');
    expect(controller.error.value, isNull);
    expect(controller.isLoading.value, isFalse);
  });

  test('loadProfile expone el mensaje de un fallo', () async {
    repo.failure = const ProfileFailure('Sin conexión. Verifica tu red.');

    await controller.loadProfile();

    expect(controller.profile, isNull);
    expect(controller.error.value, contains('Sin conexión'));
  });

  test('updateProfile guarda y devuelve true', () async {
    final ok = await controller.updateProfile(
      program: 'Derecho',
      institution: 'Uninorte',
      bio: 'Hola',
      skills: ['Oratoria'],
    );

    expect(ok, isTrue);
    expect(controller.profile?.academicInfo, 'Derecho - Uninorte');
    expect(controller.isSaving.value, isFalse);
  });

  test('updateProfile devuelve false y deja el error si falla', () async {
    repo.failure = const ProfileFailure(
      'No tienes permiso para editar este perfil.',
    );

    final ok = await controller.updateProfile(
      program: '',
      institution: '',
      bio: '',
      skills: const [],
    );

    expect(ok, isFalse);
    expect(controller.error.value, contains('permiso'));
  });

  test('clear olvida el perfil de la sesión que se va', () async {
    await controller.loadProfile();

    controller.clear();

    expect(controller.profile, isNull);
    expect(controller.error.value, isNull);
  });

  test('una carga de la sesión anterior no pisa a la nueva', () async {
    // Sesión A empieza a cargar y queda a medias.
    final gateA = Completer<UserProfile>();
    repo.gate = gateA;
    final slow = controller.loadProfile();

    // Cierra sesión A y entra B, que carga rápido.
    controller.clear();
    repo.gate = null;
    repo.me = const UserProfile(program: 'Perfil de B');
    await controller.loadProfile();

    // Llega la respuesta tardía de A.
    gateA.complete(const UserProfile(program: 'Perfil de A'));
    await slow;

    expect(controller.profile?.program, 'Perfil de B');
    expect(controller.isLoading.value, isFalse);
  });
}
