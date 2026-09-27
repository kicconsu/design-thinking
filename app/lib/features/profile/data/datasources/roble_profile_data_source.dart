import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'package:imker/core/roble/roble_client.dart';

import 'i_profile_data_source.dart';

/// Datasource real: lee y escribe la fila del usuario en la tabla `profile`.
///
/// La lectura devuelve
/// todas las filas y la propia se busca por `_owner`.
class RobleProfileDataSource with UiLoggy implements IProfileDataSource {
  RobleProfileDataSource(this._client);

  final RobleClient _client;

  @override
  Future<Map<String, dynamic>?> readMyProfile() => _readOwnRow(action: 'leer');

  @override
  Future<Map<String, dynamic>?> ensureMyProfile({required String name}) async {
    final userId = _client.currentUserId;
    if (userId == null || userId.isEmpty) {
      loggy.warning(
        'ProfileDataSource: sin sesión — no se garantiza ninguna fila.',
      );
      return null;
    }

    final own = await _readOwnRow(action: 'comprobar');
    if (own != null) return own;

    final created = await _client.db.create(RobleClient.profileTable, {
      'name': name,
      'career': <String, dynamic>{},
      'skills': <dynamic>[],
      'profilePicture': '',
      'description': '',
    });
    loggy.info('ProfileDataSource: fila creada para name: $name');
    return created;
  }

  @override
  Future<Map<String, dynamic>> updateMyProfile({
    required String bio,
    required List<String> skills,
  }) async {
    final payload = {
      'description': bio,
      // La tabla `profile` guarda `skills` como lista plana, a diferencia de
      // `project` que envuelve sus columnas json como {"values": [...]}.
      'skills': skills,
    };

    final own = await _readOwnRow(action: 'editar');
    if (own != null && own['_id'] != null) {
      loggy.debug(
        'ProfileDataSource: updating row _id=${own['_id']} _owner=${own['_owner']} '
        'currentUserId=${_client.currentUserId}',
      );
      await _client.db.update(
        RobleClient.profileTable,
        own['_id'].toString(),
        payload,
      );
      return {...own, ...payload};
    }

    // No debería pasar (la fila se crea al entrar), pero si falta se crea
    // aquí para no dejar al usuario sin poder guardar su perfil.
    loggy.warning(
      'ProfileDataSource: sin fila propia (currentUserId=${_client.currentUserId}), creando una nueva',
    );
    final name = await _displayName();
    return _client.db.create(RobleClient.profileTable, {
      'name': name,
      'career': <String, dynamic>{},
      'profilePicture': '',
      ...payload,
    });
  }

  Future<Map<String, dynamic>?> _readOwnRow({required String action}) async {
    final rows = await _client.db.read(RobleClient.profileTable);
    final userId = _client.currentUserId;
    if (userId == null || userId.isEmpty) {
      loggy.warning(
        'ProfileDataSource: sin sesión — no se puede $action la fila propia.',
      );
      return null;
    }
    for (final row in rows) {
      if (row['_owner']?.toString() == userId) return row;
    }
    loggy.info(
      'ProfileDataSource: ninguna de las ${rows.length} filas tiene _owner == $userId '
      '(el usuario todavía no tiene fila).',
    );
    return null;
  }

  /// Nombre para una fila recién creada: el del perfil de autenticación.
  Future<String> _displayName() async {
    try {
      final me = await _client.db.currentUser();
      return ((me['name'] as String?) ?? '').trim();
    } on RobleApiException catch (e) {
      loggy.warning('ProfileDataSource: no se pudo leer el nombre — $e');
      return '';
    }
  }
}
