import 'dart:async';

import 'package:imker/features/auth/domain/models/authentication_user.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';

/// Repositorio de autenticación en memoria para probar quien lo usa.
///
/// Cada resultado se fija por campo; si un campo `*Error` está puesto, la
/// operación lanza en lugar de responder. Anota cada llamada en [calls].
class FakeAuthRepository implements IAuthRepository {
  bool loginResult = true;
  bool restoreResult = false;
  bool signUpResult = true;
  bool guestResult = true;
  bool upgradeResult = true;

  Object? loginError;
  Object? restoreError;
  Object? signUpError;
  Object? logOutError;
  Object? guestError;
  Object? upgradeError;

  /// Quién queda con la sesión abierta.
  AuthenticationUser? user = AuthenticationUser(
    id: 'user-1',
    email: 'ana@uninorte.edu.co',
    name: 'Ana',
    password: '',
  );

  final calls = <String>[];
  AuthenticationUser? lastLogin;
  AuthenticationUser? lastSignUp;

  bool _anonymous = false;
  final _expired = StreamController<void>.broadcast();

  /// Simula que la sesión se cae sin que nadie la cierre.
  void expireSession() => _expired.add(null);

  @override
  bool get isAnonymous => _anonymous;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  Future<bool> login(AuthenticationUser user) async {
    calls.add('login');
    lastLogin = user;
    if (loginError != null) throw loginError!;
    _anonymous = false;
    return loginResult;
  }

  @override
  Future<bool> restoreSession() async {
    calls.add('restoreSession');
    if (restoreError != null) throw restoreError!;
    return restoreResult;
  }

  @override
  Future<AuthenticationUser?> getLoggedUser() async => user;

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    calls.add('signUp');
    lastSignUp = user;
    if (signUpError != null) throw signUpError!;
    return signUpResult;
  }

  @override
  Future<bool> logOut() async {
    calls.add('logOut');
    if (logOutError != null) throw logOutError!;
    return true;
  }

  @override
  Future<bool> signInAnonymously() async {
    calls.add('signInAnonymously');
    if (guestError != null) throw guestError!;
    _anonymous = guestResult;
    return guestResult;
  }

  @override
  Future<bool> upgradeAccount(
    String email,
    String password,
    String name,
  ) async {
    calls.add('upgradeAccount');
    if (upgradeError != null) throw upgradeError!;
    _anonymous = !upgradeResult;
    return upgradeResult;
  }
}
