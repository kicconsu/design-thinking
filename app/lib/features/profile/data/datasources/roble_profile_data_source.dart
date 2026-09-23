import 'package:loggy/loggy.dart';

import 'package:imker/core/roble/roble_client.dart';

import 'i_profile_data_source.dart';

/// Datasource real: lee y actualiza la fila del usuario en la tabla
/// `profile` de Roble (la misma que crea `_syncProfile` en el login/signup).
class RobleProfileDataSource with UiLoggy implements IProfileDataSource {
  RobleProfileDataSource(this._client);

  final RobleClient _client;

  @override
  Future<Map<String, dynamic>?> readMyProfile() async {
    final rows = await _client.db.read(RobleClient.profileTable);
    return _findOwnRow(rows);
  }

  @override
  Future<Map<String, dynamic>> updateMyProfile({
    required String bio,
    required List<String> skills,
  }) async {
    final rows = await _client.db.read(RobleClient.profileTable);
    final own = _findOwnRow(rows);

    final payload = {
      'description': bio,
      // La tabla `profile` guarda `skills` como lista plana (ver
      // AuthenticationSourceService._syncProfile), a diferencia de `project`
      // que envuelve sus columnas json como {"values": [...]}.
      'skills': skills,
    };

    if (own != null && own['_id'] != null) {
      loggy.debug(
        'ProfileDataSource: updating row _id=${own['_id']} _owner=${own['_owner']} '
        'currentUserId=${_client.currentUserId}',
      );
      await _client.db.update(RobleClient.profileTable, own['_id'].toString(), payload);
      return {...own, ...payload};
    }

    // No debería pasar (la fila se crea en signup/upgrade), pero si falta,
    // la creamos para no dejar al usuario sin poder guardar su perfil.
    loggy.warning(
      'ProfileDataSource: no existing row found for currentUserId=${_client.currentUserId}, creando una nueva',
    );
    return _client.db.create(RobleClient.profileTable, {
      'name': '',
      'career': <String, dynamic>{},
      'profilePicture': '',
      ...payload,
    });
  }

  Map<String, dynamic>? _findOwnRow(List<Map<String, dynamic>> rows) {
    final userId = _client.currentUserId;
    if (userId == null) {
      loggy.warning(
        'ProfileDataSource: currentUserId es null — no se puede identificar la fila propia '
        'con certeza, usando la primera fila de ${rows.length} recibidas.',
      );
      return rows.isNotEmpty ? rows.first : null;
    }
    for (final row in rows) {
      if (row['_owner']?.toString() == userId) return row;
    }
    loggy.warning(
      'ProfileDataSource: ninguna de las ${rows.length} filas tiene _owner == $userId — '
      'usando la primera fila como último recurso.',
    );
    return rows.isNotEmpty ? rows.first : null;
  }
}
