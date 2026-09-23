import 'package:imker/core/roble/roble_client.dart';

import 'i_project_data_source.dart';

class RobleProjectDataSource implements IProjectDataSource {
  RobleProjectDataSource(this._client);

  final RobleClient _client;

  @override
  Future<List<Map<String, dynamic>>> readProjects() =>
      _client.readPublicOrPrivate(RobleClient.projects);

  @override
  Future<List<Map<String, dynamic>>> readProjectsByOwner(String ownerId) async {
    if (_client.readsPublicly) {
      return _client.db.publicRead(RobleClient.projects, filters: {'_owner': ownerId});
    }
    try {
      // Intento 1: filtro en el servidor por _owner exacto.
      if (ownerId.isNotEmpty) {
        final filtered = await _client.db.read(RobleClient.projects, filters: {'_owner': ownerId});
        if (filtered.isNotEmpty) return filtered;
      }

      // Intento 2: leer todos y filtrar del lado cliente con matchesUser.
      // Necesario cuando Roble guarda el _owner en un formato distinto al ownerId cacheado.
      final all = await _client.db.read(RobleClient.projects);
      final matched = all.where((r) => _client.matchesUser(r['_owner']?.toString())).toList();
      return matched;
    } catch (_) {}
    return [];
  }




  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async {
    // getById no está disponible en lectura pública; publicRead filtra por _id.
    if (!_client.readsPublicly) return _client.db.getById(RobleClient.projects, id);
    final rows = await _client.db.publicRead(RobleClient.projects, filters: {'_id': id});
    return rows.firstOrNull;
  }

  @override
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData) async {
    return await _client.db.create(RobleClient.projects, projectData);
  }
}

