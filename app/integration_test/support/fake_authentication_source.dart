import 'package:imker/features/auth/data/datasources/remote/i_authentication_source.dart';
import 'package:imker/features/auth/domain/models/authentication_user.dart';

import 'fake_roble_client.dart';

/// Autenticación de prueba: una sola cuenta, sin servidor.
///
/// Arranca sin sesión (la app cae en el login) y entra con
/// [email] / [password]. Al entrar enciende la sesión del [FakeRobleDb] para
/// que el resto de la app vea el mismo `user_id` que [getLoggedUser].
class FakeAuthenticationSource implements IAuthenticationSource {
  FakeAuthenticationSource({
    required this.db,
    required this.name,
    this.email = 'usuario@test.imker',
    this.password = 'Prueba123!',
  });

  final FakeRobleDb db;
  final String name;
  final String email;
  final String password;

  bool _inside = false;

  @override
  Future<bool> login(AuthenticationUser user) async {
    final sameEmail = user.email.trim().toLowerCase() == email;
    if (!sameEmail || user.password != password) {
      throw StateError('Credenciales incorrectas');
    }
    _inside = true;
    db.signedIn = true;
    return true;
  }

  @override
  Future<bool> restoreSession() async => _inside;

  @override
  Future<AuthenticationUser?> getLoggedUser() async {
    if (!_inside) return null;
    return AuthenticationUser(
      id: db.userId,
      email: email,
      name: name,
      password: '',
    );
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async => true;

  @override
  Future<bool> logOut() async {
    _inside = false;
    db.signedIn = false;
    return true;
  }

  @override
  Future<bool> signInAnonymously() async => false;

  @override
  Future<bool> upgradeAccount(
    String email,
    String password,
    String name,
  ) async => false;

  @override
  bool get isAnonymous => false;

  @override
  Stream<void> get sessionExpired => const Stream.empty();
}
