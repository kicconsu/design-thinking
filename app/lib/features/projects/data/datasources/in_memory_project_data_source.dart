import 'package:imker/features/projects/domain/fixtures/project_fixtures.dart';

import 'i_project_data_source.dart';

/// Backend falso: sirve las mismas filas que devolvería Roble.
/// Útil para desarrollo sin red y para pruebas unitarias del repositorio.
class InMemoryProjectDataSource implements IProjectDataSource {
  static final List<Map<String, dynamic>> _data = ProjectFixtures.rows;

  @override
  Future<List<Map<String, dynamic>>> readProjects() async => _data;

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async =>
      _data.where((r) => r['_id'] == id).firstOrNull;
}
