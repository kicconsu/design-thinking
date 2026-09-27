import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'package:imker/core/roble/roble_client.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

/// Datasource de autenticación real, respaldado por el SDK de Roble.
///
/// El paquete guarda, refresca y renueva los tokens: aquí no se tocan. Lo único
/// que queda en la app es traducir el perfil del servidor al modelo propio.
///
/// Las tablas de negocio (por ejemplo `profile`) no son cosa suya: si la sesión
/// necesita una fila, la pide el coordinador de auth a `features/profile`.
class AuthenticationSourceService
    with UiLoggy
    implements IAuthenticationSource {
  AuthenticationSourceService(this._client);

  final RobleClient _client;

  RobleApiDataBase get _db => _client.db;

  @override
  Stream<void> get sessionExpired => _db.onSessionExpired;

  // ─── Sesión ───────────────────────────────────────────────────────────────

  @override
  Future<bool> restoreSession() async {
    loggy.debug('AuthSource: restoreSession');
    try {
      final restored = await _db.restoreSession();
      return restored;
    } on RobleApiNetworkException catch (e) {
      loggy.warning('AuthSource: restoreSession sin conexión — $e');
      return _hasSessionInMemory();
    } on RobleApiTimeoutException catch (e) {
      loggy.warning('AuthSource: restoreSession sin respuesta — $e');
      return _hasSessionInMemory();
    } on RobleApiException catch (e) {
      // Refresh token rechazado: el paquete ya limpió la sesión guardada.
      loggy.warning('AuthSource: restoreSession failed — $e');
      return false;
    }
  }

  bool _hasSessionInMemory() {
    if (!_db.isLoggedIn) return false;
    loggy.info('AuthSource: se sigue con la sesión guardada en local');
    return true;
  }

  @override
  Future<bool> login(AuthenticationUser user) async {
    loggy.debug('AuthSource: login ${user.email}');
    await _db.login(email: user.email, password: user.password);
    return true;
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    final name = user.name.trim().isEmpty ? user.email : user.name.trim();
    loggy.debug('AuthSource: register ${user.email}');
    // `register` crea la cuenta sin dejar sesión abierta. Es a propósito: el
    // que llama decide si entrar después, y así no hay que cerrar una sesión
    // que a veces ya no existe.
    await _db.register(email: user.email, password: user.password, name: name);
    return true;
  }

  @override
  Future<bool> logOut() async {
    loggy.debug('AuthSource: logout');
    try {
      await _db.logout();
    } on RobleApiException catch (e) {
      // El servidor ya no reconoce la sesión: la app puede no reaccionar, ya que de todos
      // modos el paquete desechó los tokens.
      loggy.warning('AuthSource: logout error — $e');
    }
    return true;
  }

  @override
  Future<AuthenticationUser?> getLoggedUser() async {
    if (!_db.isLoggedIn) return null;
    try {
      final profile = await _db.currentUser();
      return _toUser(profile);
    } on RobleApiNetworkException catch (e) {
      loggy.warning('AuthSource: getLoggedUser sin conexión — $e');
      return _cachedUser();
    } on RobleApiTimeoutException catch (e) {
      loggy.warning('AuthSource: getLoggedUser sin respuesta — $e');
      return _cachedUser();
    } on RobleApiException catch (e) {
      loggy.warning('AuthSource: getLoggedUser error — $e');
      return null;
    }
  }

  AuthenticationUser _toUser(Map<String, dynamic> profile) =>
      AuthenticationUser(
        // `userId` es el que referencian las tablas; `id` es el de la fila de
        // `user_system` y no sirve para comparar con `_owner`.
        id: (profile['userId'] ?? profile['id'])?.toString(),
        email: profile['email'] as String? ?? '',
        name: (profile['name'] as String?)?.trim() ?? '',
        password: '',
      );

  /// Sin red no hay `/me`, pero el paquete deja el último perfil que vio.
  AuthenticationUser? _cachedUser() {
    final cached = _db.authState.user;
    if (cached == null) return null;
    return AuthenticationUser(
      id: cached.userId,
      email: cached.email,
      name: cached.name.trim(),
      password: '',
    );
  }

  // ─── Invitado ─────────────────────────────────────────────────────────────

  @override
  Future<bool> signInAnonymously() async {
    loggy.debug('AuthSource: signInAnonymously');
    await _db.signInAnonymously();
    return true;
  }

  @override
  bool get isAnonymous => _db.isAnonymous;

  @override
  Future<bool> upgradeAccount(
    String email,
    String password,
    String name,
  ) async {
    loggy.debug('AuthSource: upgradeAccount $email');
    final effectiveName = name.trim().isEmpty ? email : name.trim();
    await _db.upgradeAccount(
      email: email,
      password: password,
      name: effectiveName,
    );
    return true;
  }
}
