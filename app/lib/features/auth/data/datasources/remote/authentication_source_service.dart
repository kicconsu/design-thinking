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
      if (restored) {
        await _cacheCurrentUserId();
      }
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
      await _cacheCurrentUserId();
      final profile = await _db.currentUser();
      final currentName = (profile['name'] as String?)?.trim() ?? '';
      await _syncProfile(
        name: currentName.isNotEmpty ? currentName : user.email,
      );
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
    loggy.debug('AuthSource: register ${user.email}');
    final name = user.name.trim().isEmpty ? user.email : user.name.trim();
    try {
      try {
        // Intentar registro directo estándar (POST /signup-direct)
        await _db.register(
          email: user.email,
          password: user.password,
          name: name,
          autoLogin: true,
        );
      } on RobleApiHttpException catch (httpError) {
        // Si Roble aplica rate limiting (429) en /signup-direct:
        // bypasseamos usando el endpoint separado /me/upgrade-direct vía sesión anónima.
        if (httpError.statusCode == 429) {
          loggy.warning(
            'AuthSource: 429 en signup-direct. Aplicando bypass vía signInAnonymously + upgradeAccount...',
          );
          await _db.signInAnonymously();
          await _db.upgradeAccount(
            email: user.email,
            password: user.password,
            name: name,
          );
        } else {
          rethrow;
        }
      }
      await _cacheCurrentUserId();
      // Crear fila en tabla `profile` vinculada al _owner recién registrado.
      await _syncProfile(name: name);
      // Cerrar sesión para que el usuario haga login explícito si ese es el flujo.
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
      String name = profile['name'] as String? ?? '';
      // Si currentUser() todavía tiene 'Invitado' o viene vacío pero tenemos sesión real,
      // buscamos si en la tabla profile ya está su nombre real.
      if (name.isEmpty || name == 'Invitado') {
        try {
          final rows = await _db.read(RobleClient.profileTable);
          if (rows.isNotEmpty) {
            final rowName = rows.first['name'] as String?;
            if (rowName != null &&
                rowName.trim().isNotEmpty &&
                rowName != 'Invitado') {
              name = rowName.trim();
            }
          }
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
      await _cacheCurrentUserId();
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
      await _cacheCurrentUserId();
      // Insertar o actualizar la fila en la tabla `profile` de Roble
      await _syncProfile(name: effectiveName);
      return true;
    } on RobleApiException catch (e) {
      loggy.error('AuthSource: upgradeAccount error — $e');
      rethrow;
    }
  }

  // ─── Otros (no usados activamente, stubs para cumplir contrato) ───────────

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
  ) async => true;

  @override
  Future<bool> verifyToken() async => _db.isLoggedIn;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _cacheCurrentUserId() async {
    try {
      final profile = await _db.currentUser();
      _client.currentUserIdentifiers.clear();

      for (final key in ['user_id', '_owner', 'id', '_id', 'email']) {
        final val = profile[key]?.toString();
        if (val != null && val.trim().isNotEmpty) {
          _client.currentUserIdentifiers.add(val.trim());
        }
      }

      final primaryId =
          (profile['user_id'] ??
                  profile['_owner'] ??
                  profile['id'] ??
                  profile['_id'])
              ?.toString();
      _client.currentUserId = primaryId;
      _client.currentUserEmail = profile['email']?.toString();
    } catch (_) {}
  }

  /// Sincroniza la fila del usuario en la tabla `profile` de Roble según el UML:
  /// - _owner: FK a user_system (manejado por Roble)
  /// - name: text (*)
  /// - career: json (*)
  /// - skills: json
  /// - profilePicture: varchar
  /// - description: text
  Future<void> _syncProfile({required String name}) async {
    try {
      final current = await _db.currentUser();
      loggy.debug(current);
      final userId =
          current['userId']?.toString() ?? _client.currentUserId ?? '';

      List<dynamic> rows = [];
      try {
        rows = await _db.read(RobleClient.profileTable);
      } catch (readErr) {
        loggy.warning('AuthSource: read profile table error — $readErr');
      }

      Map<String, dynamic>? existing;
      for (final r in rows) {
        if (r is Map<String, dynamic>) {
          if (userId.isNotEmpty && r['_owner']?.toString() == userId) {
            existing = r;
            break;
          }
        }
      }

      if (existing != null && existing['_id'] != null) {
        await _db.update(RobleClient.profileTable, existing['_id'].toString(), {
          'name': name,
        });
        loggy.info('AuthSource: profile updated in table with name: $name');
      } else {
        final created = await _db.create(RobleClient.profileTable, {
          'name': name,
          'career': <String, dynamic>{},
          'skills': <dynamic>[],
          'profilePicture': '',
          'description': '',
        });
        loggy.info('AuthSource: profile created in table profile: $created');
      }
    } catch (e, st) {
      loggy.error('AuthSource: _syncProfile failed — $e', st);
    }
  }
}
