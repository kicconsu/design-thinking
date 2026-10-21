import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/core/widgets/profile_avatar.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/projects/domain/models/project.dart';

Project _project(String id, String title) => Project(
  id: id,
  title: title,
  imageUrl: '',
  description: '',
  jobs: const [],
  skills: const [],
);

Widget _host(Widget child) => GetMaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

class _FakeAuth implements IAuthRepository {
  bool loggedOut = false;

  @override
  Future<bool> logOut() async => loggedOut = true;

  @override
  Future<bool> restoreSession() async => false;

  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  bool get isAnonymous => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _full = UserProfile(
  program: 'Ingeniería de Sistemas',
  institution: 'Uninorte',
  bio: 'Me gustan los datos.',
  skills: ['Python', 'SQL'],
);

void main() {
  group('ProfileAvatar.initialsOf', () {
    test('toma la inicial de las dos primeras palabras', () {
      expect(ProfileAvatar.initialsOf('Valentina Ríos Pérez'), 'VR');
      expect(ProfileAvatar.initialsOf('  juan '), 'J');
    });

    test('sin nombre muestra un signo de interrogación', () {
      expect(ProfileAvatar.initialsOf('   '), '?');
    });
  });
}
