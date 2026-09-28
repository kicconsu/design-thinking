import 'package:imker/core/data/dummy_data.dart';

import 'i_project_data_source.dart';

/// Backend falso: sirve las mismas filas que devolvería Roble desde memoria.
/// Útil para desarrollo sin red y para pruebas unitarias del repositorio.
class InMemoryProjectDataSource implements IProjectDataSource {
  InMemoryProjectDataSource([DummyData? data])
    : _data = data ?? DummyData.instance;

  final DummyData _data;
  final List<Map<String, dynamic>> _joinRequests = [];
  final List<Map<String, dynamic>> _projectMembers = [];
  final List<Map<String, dynamic>> _saved = [];

  @override
  Future<List<Map<String, dynamic>>> readProjects() async => _data.projects;

  @override
  Future<List<Map<String, dynamic>>> readProjectsByOwner(
    String ownerId,
  ) async => _data.projects.where((r) => r['_owner'] == ownerId).toList();

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async =>
      _data.projects.where((r) => r['_id'] == id).firstOrNull;

  @override
  Future<Map<String, dynamic>> createProject(
    Map<String, dynamic> projectData,
  ) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final row = <String, dynamic>{
      '_id': newId,
      '_owner': 'demo-owner',
      ...projectData,
    };
    _data.projects.add(row);
    return row;
  }

  @override
  Future<Map<String, dynamic>> createJoinRequest(
    Map<String, dynamic> joinRequestData,
  ) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final row = <String, dynamic>{
      '_id': newId,
      '_owner': joinRequestData['user_id'] ?? 'demo-user',
      'user_id': joinRequestData['user_id'] ?? 'demo-user',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      ...joinRequestData,
    };
    _joinRequests.add(row);
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(
    String userId,
  ) async {
    return _joinRequests
        .where((r) => r['user_id'] == userId || r['_owner'] == userId)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsForProject(
    String projectId,
  ) async {
    return _joinRequests.where((r) => r['project_id'] == projectId).toList();
  }

  @override
  Future<Map<String, dynamic>> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    final idx = _joinRequests.indexWhere(
      (r) => r['_id'] == requestId || r['id'] == requestId,
    );
    if (idx != -1) {
      _joinRequests[idx]['status'] = {'state': status};
      _joinRequests[idx]['reviewed_by'] = reviewedBy;
      _joinRequests[idx]['updatedAt'] = DateTime.now().toIso8601String();
      if (reviewNote != null) _joinRequests[idx]['reviewNote'] = reviewNote;
      return _joinRequests[idx];
    }
    return {
      '_id': requestId,
      'status': {'state': status},
      'reviewed_by': reviewedBy,
    };
  }

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async {
    return {
      '_id': 'profile-$userId',
      '_owner': userId,
      'name': 'Usuario Demo',
      'description': 'Perfil de prueba',
      'skills': ['Flutter', 'Dart'],
    };
  }

  @override
  Future<Map<String, dynamic>> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  }) async {
    final row = {
      '_id': 'member-${DateTime.now().millisecondsSinceEpoch}',
      'project_id': projectId,
      'user_id': userId,
      'role': role ?? {'name': 'collaborator'},
    };
    _projectMembers.add(row);
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> readProjectMembers({
    String? projectId,
  }) async {
    if (projectId != null && projectId.isNotEmpty) {
      return _projectMembers
          .where((r) => r['project_id'] == projectId)
          .toList();
    }
    return _projectMembers;
  }

  @override
  Future<List<Map<String, dynamic>>> readSavedByUser(String userId) async {
    return _saved.where((r) => r['user_id'] == userId).toList();
  }

  @override
  Future<Map<String, dynamic>> createSaved({
    required String userId,
    required String projectId,
  }) async {
    final existing = _saved.firstWhere(
      (r) => r['user_id'] == userId && r['project_id'] == projectId,
      orElse: () => const {},
    );
    if (existing.isNotEmpty) return existing;

    final row = <String, dynamic>{
      '_id': 'saved-${DateTime.now().microsecondsSinceEpoch}',
      '_owner': userId,
      'user_id': userId,
      'project_id': projectId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _saved.add(row);
    return row;
  }

  @override
  Future<void> deleteSaved({
    required String userId,
    required String projectId,
  }) async {
    _saved.removeWhere(
      (r) => r['user_id'] == userId && r['project_id'] == projectId,
    );
  }
}
