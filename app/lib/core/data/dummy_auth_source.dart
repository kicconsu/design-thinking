import 'package:imker/features/auth/data/datasources/remote/i_authentication_source.dart';
import 'package:imker/features/auth/domain/models/authentication_user.dart';

/// Datasource de autenticación en memoria para desarrollo sin credenciales Roble.
///
/// Guarda cuentas en una lista en memoria (se resetean al cerrar la app).
/// Permite probar login/signup/invitado sin necesitar el backend real.
///
/// Activado en [auth_dependencies.dart] cuando [RobleClient] no está registrado.
class DummyAuthSource implements IAuthenticationSource {
  static const _demoEmail = 'demo@imker.co';
  static const _demoPassword = 'ThePassword1!';
  static const _demoName = 'Demo User';

  final _accounts = <String, _Account>{
    _demoEmail: _Account(email: _demoEmail, password: _demoPassword, name: _demoName),
  };

  _Account? _session;
  bool _isAnonymous = false;

  @override
  Future<bool> login(AuthenticationUser user) async {
    final email = user.email.trim().toLowerCase();
    final account = _accounts[email];
    if (account == null || account.password != user.password) {
      throw StateError('Credenciales incorrectas');
    }
    _session = account;
    _isAnonymous = false;
    return true;
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    final email = user.email.trim().toLowerCase();
    if (_accounts.containsKey(email)) {
      throw StateError('Este correo ya tiene cuenta');
    }
    _accounts[email] = _Account(
      email: email,
      password: user.password,
      name: user.name.trim().isEmpty ? email : user.name.trim(),
    );
    return true;
  }

  @override
  Future<bool> logOut() async {
    _session = null;
    _isAnonymous = false;
    return true;
  }

  @override
  Future<bool> restoreSession() async => _session != null || _isAnonymous;

  @override
  Future<AuthenticationUser?> getLoggedUser() async {
    if (_session == null && !_isAnonymous) return null;
    if (_isAnonymous) {
      return AuthenticationUser(
        id: 0,
        email: 'guest@anonymous.invalid',
        name: 'Invitado',
        password: '',
      );
    }
    return AuthenticationUser(
      id: _session.hashCode,
      email: _session!.email,
      name: _session!.name,
      password: '',
    );
  }

  // ─── Invitado ─────────────────────────────────────────────────────────────

  @override
  Future<bool> signInAnonymously() async {
    _isAnonymous = true;
    _session = null;
    return true;
  }

  @override
  bool get isAnonymous => _isAnonymous;

  @override
  Future<bool> upgradeAccount(String email, String password, String name) async {
    final normalized = email.trim().toLowerCase();
    if (_accounts.containsKey(normalized)) {
      throw StateError('Este correo ya tiene cuenta');
    }
    _accounts[normalized] = _Account(email: normalized, password: password, name: name);
    _session = _accounts[normalized];
    _isAnonymous = false;
    return true;
  }

  // ─── Stubs del contrato ───────────────────────────────────────────────────

  @override
  Future<bool> validate(String email, String validationCode) async => true;

  @override
  Future<bool> refreshToken() async => true;

  @override
  Future<bool> forgotPassword(String email) async => true;

  @override
  Future<bool> resetPassword(
    String email,
    String newPassword,
    String validationCode,
  ) async =>
      true;

  @override
  Future<bool> verifyToken() async => _session != null || _isAnonymous;
}

class _Account {
  final String email;
  final String password;
  final String name;
  const _Account({required this.email, required this.password, required this.name});
}
