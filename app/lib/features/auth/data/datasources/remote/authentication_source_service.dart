import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'package:imker/core/roble/roble_client.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

/// Datasource de autenticación real, respaldado por el SDK de Roble.
class AuthenticationSourceService
    with UiLoggy
    implements IAuthenticationSource {
  final RobleClient _client;

  AuthenticationSourceService(this._client);

  RobleApiDataBase get _db => _client.db;

  // ─── Sesión ───────────────────────────────────────────────────────────────

  @override
  Future<bool> restoreSession() async {
    loggy.debug('AuthSource: restoreSession');
    try {
      final restored = await _db.restoreSession();
      if (restored) _cacheCurrentUserId();
      return restored;
    } on RobleApiException catch (e) {
      loggy.warning('AuthSource: restoreSession failed — $e');
      return false;
    }
  }

  @override
  Future<bool> login(AuthenticationUser user) async {
    loggy.debug('AuthSource: login ${user.email}');
    try {
      await _db.login(email: user.email, password: user.password);
      _cacheCurrentUserId();
      return true;
    } on RobleApiAuthException catch (e) {
      loggy.warning('AuthSource: login auth error — $e');
      rethrow;
    } on RobleApiException catch (e) {
      loggy.error('AuthSource: login error — $e');
      rethrow;
    }
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    final name = user.name.trim().isEmpty ? user.email : user.name.trim();
    loggy.debug('AuthSource: register ${user.email}');
    try {
      await _db.register(
        email: user.email,
        password: user.password,
        name: name,
        autoLogin: true,
      );
      _cacheCurrentUserId();
      await _syncProfile(name: name);
      await _db.logout();
      return true;
    } on RobleApiException catch (e) {
      loggy.error('AuthSource: register error — $e');
      rethrow;
    }
  }

  @override
  Future<bool> logOut() async {
    loggy.debug('AuthSource: logout');
    try {
      await _db.logout();
    } on RobleApiException catch (e) {
      loggy.error('AuthSource: logout error — $e');
    } finally {
      _client.currentUserId = null;
      _client.currentUserEmail = null;
      _client.currentUserIdentifiers.clear();
    }
    return true;
  }

  @override
  Future<AuthenticationUser?> getLoggedUser() async {
    if (!_db.isLoggedIn) return null;
    try {
      final profile = await _db.currentUser();
      String name = (profile['name'] as String?)?.trim() ?? '';

      // Los invitados tienen nombre sintético del servidor; no buscamos en
      // la tabla de perfil porque tampoco van a tener fila allí todavía.
      if (!_db.isAnonymous && (name.isEmpty || name == 'Invitado')) {
        try {
          final rows = await _db.read(
            RobleClient.profileTable,
            filters: {'_owner': _db.currentUserId},
          );
          final rowName = (rows.firstOrNull?['name'] as String?)?.trim() ?? '';
          if (rowName.isNotEmpty && rowName != 'Invitado') name = rowName;
        } catch (_) {}
      }

      return AuthenticationUser(
        id: profile['_id'] as int? ?? 0,
        email: profile['email'] as String? ?? '',
        name: name,
        password: '',
      );
    } on RobleApiException catch (e) {
      loggy.warning('AuthSource: getLoggedUser error — $e');
      return null;
    }
  }

  // ─── Invitado ─────────────────────────────────────────────────────────────

  @override
  Future<bool> signInAnonymously() async {
    loggy.debug('AuthSource: signInAnonymously');
    try {
      await _db.signInAnonymously();
      _cacheCurrentUserId();
      return true;
    } on RobleApiException catch (e) {
      loggy.error('AuthSource: signInAnonymously error — $e');
      rethrow;
    }
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
    try {
      await _db.upgradeAccount(
        email: email,
        password: password,
        name: effectiveName,
      );
      _cacheCurrentUserId();
      await _syncProfile(name: effectiveName);
      return true;
    } on RobleApiException catch (e) {
      loggy.error('AuthSource: upgradeAccount error — $e');
      rethrow;
    }
  }

  // ─── Otros (stubs para cumplir el contrato) ───────────────────────────────

  @override
  Future<bool> validate(String email, String validationCode) async => true;

  @override
  Future<bool> refreshToken() async => true;

  @override
  Future<bool> forgotPassword(String email) async {
    await _db.forgotPassword(email: email);
    return true;
  }

  @override
  Future<bool> resetPassword(
    String email,
    String newPassword,
    String validationCode,
  ) async =>
      true;

  @override
  Future<bool> verifyToken() async => _db.isLoggedIn;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Actualiza [RobleClient] con los identificadores de la sesión activa.
  ///
  /// Lee desde el JWT en memoria (sin red) usando [RobleApiDataBase.currentUserId],
  /// que devuelve el `sub` del token. El email requiere un [currentUser()] pero
  /// no es crítico para filtrar por _owner, así que solo se guarda el userId.
  void _cacheCurrentUserId() {
    final userId = _db.currentUserId;
    _client.currentUserIdentifiers.clear();
    if (userId != null && userId.isNotEmpty) {
      _client.currentUserId = userId;
      _client.currentUserIdentifiers.add(userId);
    }
  }

  /// Crea o actualiza la fila del usuario en la tabla `profile`.
  ///
  /// Roble filtra [read] por el `_owner` de la sesión activa, así que la
  /// primera fila del resultado (si existe) es siempre la del usuario actual.
  /// No hace falta buscar manualmente por `_owner`.
  ///
  /// Columnas de la tabla según el UML:
  /// - `name` text (*)
  /// - `career` json (*)
  /// - `skills` json
  /// - `profilePicture` varchar
  /// - `description` text
  Future<void> _syncProfile({required String name}) async {
    try {
      final rows = await _db.read(
        RobleClient.profileTable,
        filters: {'_owner': _db.currentUserId},
      );
      final existing = rows.firstOrNull;

      if (existing != null && existing['_id'] != null) {
        await _db.update(
          RobleClient.profileTable,
          existing['_id'].toString(),
          {'name': name},
        );
        loggy.info('AuthSource: profile updated — name: $name');
      } else {
        await _db.create(RobleClient.profileTable, {
          'name': name,
          'career': <String, dynamic>{},
          'skills': <dynamic>[],
          'profilePicture': '',
          'description': '',
        });
        loggy.info('AuthSource: profile created — name: $name');
      }
    } catch (e, st) {
      loggy.error('AuthSource: _syncProfile failed — $e', st);
    }
  }
}
