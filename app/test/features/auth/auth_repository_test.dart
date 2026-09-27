import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:imker/features/auth/data/datasources/remote/i_authentication_source.dart';
import 'package:imker/features/auth/data/repositories/auth_repository.dart';
import 'package:imker/features/auth/domain/models/authentication_user.dart';

class _FakeSource implements IAuthenticationSource {
  final calls = <String>[];
  bool sessionOpen = false;
  bool failRegister = false;

  final _expired = StreamController<void>.broadcast();

  @override
  Future<bool> login(AuthenticationUser user) async {
    calls.add('login:${user.email}');
    sessionOpen = true;
    return true;
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    calls.add('register:${user.email}');
    if (failRegister) throw StateError('registro rechazado');
    return true;
  }

  @override
  Future<bool> restoreSession() async => sessionOpen;

  @override
  Future<AuthenticationUser?> getLoggedUser() async => null;

  @override
  Future<bool> logOut() async {
    calls.add('logout');
    sessionOpen = false;
    return true;
  }

  @override
  Future<bool> signInAnonymously() async {
    calls.add('guest');
    sessionOpen = true;
    return true;
  }

  @override
  Future<bool> upgradeAccount(String email, String password, String name) async {
    calls.add('upgrade:$email');
    return true;
  }

  @override
  bool get isAnonymous => false;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  void expire() => _expired.add(null);

  void dispose() => _expired.close();
}

AuthenticationUser _user(String email) =>
    AuthenticationUser(email: email, name: 'Ana', password: 'Secreta1!');

void main() {
  group('AuthRepository', () {
    late _FakeSource source;
    late AuthRepository repo;

    setUp(() {
      source = _FakeSource();
      repo = AuthRepository(source);
    });

    tearDown(() => source.dispose());

    test('signUp crea la cuenta y entra con las mismas credenciales', () async {
      expect(await repo.signUp(_user('ana@ejemplo.test')), isTrue);

      expect(source.calls, ['register:ana@ejemplo.test', 'login:ana@ejemplo.test']);
      expect(source.sessionOpen, isTrue, reason: 'quien se registra queda dentro');
    });

    test('si el registro falla no se intenta entrar', () async {
      source.failRegister = true;

      await expectLater(repo.signUp(_user('ana@ejemplo.test')), throwsStateError);
      expect(source.calls, ['register:ana@ejemplo.test']);
      expect(source.sessionOpen, isFalse);
    });

    test('logOut cierra la sesión en el datasource', () async {
      source.sessionOpen = true;

      expect(await repo.logOut(), isTrue);
      expect(source.sessionOpen, isFalse);
    });

    test('sessionExpired se delega al datasource', () async {
      var avisos = 0;
      final sub = repo.sessionExpired.listen((_) => avisos++);

      source.expire();
      await Future<void>.delayed(Duration.zero);

      expect(avisos, 1);
      await sub.cancel();
    });
  });
}
