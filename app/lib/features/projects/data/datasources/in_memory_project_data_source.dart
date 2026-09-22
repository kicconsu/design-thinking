import 'package:imker/core/data/dummy_data.dart';

import 'i_project_data_source.dart';

/// Backend falso: sirve las mismas filas que devolvería Roble desde memoria.
/// Útil para desarrollo sin red y para pruebas unitarias del repositorio.
class InMemoryProjectDataSource implements IProjectDataSource {
  InMemoryProjectDataSource([DummyData? data]) : _data = data ?? DummyData.instance;

  final DummyData _data;

  @override
  Future<List<Map<String, dynamic>>> readProjects() async => _data.projects;

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async =>
      _data.projects.where((r) => r['_id'] == id).firstOrNull;
}
