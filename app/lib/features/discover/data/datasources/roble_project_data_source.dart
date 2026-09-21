import 'package:f_clean_template/core/roble/roble_client.dart';

import 'i_project_data_source.dart';

class RobleProjectDataSource implements IProjectDataSource {
  RobleProjectDataSource(this._client);

  final RobleClient _client;

  @override
  Future<List<Map<String, dynamic>>> readProjects() =>
      _client.readPublicOrPrivate(RobleClient.projects);

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async {
    // getById no está disponible en lectura pública; publicRead filtra por _id.
    if (!_client.readsPublicly) return _client.db.getById(RobleClient.projects, id);
    final rows = await _client.db.publicRead(RobleClient.projects, filters: {'_id': id});
    return rows.firstOrNull;
  }
}
