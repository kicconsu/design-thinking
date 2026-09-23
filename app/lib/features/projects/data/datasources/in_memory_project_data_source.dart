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
  Future<List<Map<String, dynamic>>> readProjectsByOwner(String ownerId) async =>
      _data.projects.where((r) => r['_owner'] == ownerId).toList();


  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async =>
      _data.projects.where((r) => r['_id'] == id).firstOrNull;

  @override
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final row = <String, dynamic>{
      '_id': newId,
      '_owner': 'demo-owner',
      ...projectData,
    };
    _data.projects.add(row);
    return row;
  }
}

