import 'package:imker/features/projects/data/datasources/i_project_data_source.dart';

/// Datasource de proyectos para pruebas de integración: todo vive en listas
/// en memoria, con la misma forma de fila que devolvería Roble, y nada sale
/// a la red.
///
/// Las pruebas lo siembran con filas y, al terminar un flujo, lo consultan
/// ([joinRequestsOf], [activeMemberIds]…) para comprobar qué quedó
/// "guardado" sin depender de lo que muestre la pantalla.
class FakeProjectDataSource implements IProjectDataSource {
  FakeProjectDataSource({
    required this.currentUserId,
    List<Map<String, dynamic>> projects = const [],
    List<Map<String, dynamic>> joinRequests = const [],
    List<Map<String, dynamic>> members = const [],
    Map<String, Map<String, dynamic>> profiles = const {},
  }) : projects = _copy(projects),
       joinRequests = _copy(joinRequests),
       members = _copy(members),
       profiles = {for (final e in profiles.entries) e.key: Map.of(e.value)};

  static List<Map<String, dynamic>> _copy(List<Map<String, dynamic>> rows) => [
    for (final r in rows) Map<String, dynamic>.of(r),
  ];

  /// Quién tiene la sesión.
  @override
  final String currentUserId;

  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> joinRequests;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> saved = [];
  final List<Map<String, dynamic>> invitations = [];

  /// Filas de `profile` por `user_id`, para los nombres de las solicitudes.
  final Map<String, Map<String, dynamic>> profiles;

  int _seq = 0;
  String _nextId(String prefix) => '$prefix-${++_seq}';

  // ─── Consultas pensadas para las aserciones ───────────────────────────────

  /// Estado de una solicitud, sea cual sea la forma en que se guardó.
  static String stateOf(Map<String, dynamic> request) {
    final status = request['status'];
    if (status is Map) return (status['state'] ?? '').toString();
    return (status ?? '').toString();
  }

  /// Solicitudes de [projectId] (de cualquier estado).
  List<Map<String, dynamic>> joinRequestsOf(String projectId) => [
    for (final r in joinRequests)
      if (r['project_id'] == projectId) r,
  ];

  /// `user_id` de los miembros activos de [projectId].
  Set<String> activeMemberIds(String projectId) => {
    for (final m in members)
      if (m['project_id'] == projectId &&
          (m['status'] ?? 'active') == 'active')
        m['user_id'].toString(),
  };

  /// La fila de [projectId], o null.
  Map<String, dynamic>? projectRow(String projectId) =>
      projects.where((r) => r['_id'] == projectId).firstOrNull;

  /// Cambia columnas de un proyecto sin pasar por la app (lo usa el doble de
  /// tareas para dejar `progress` y `total_tasks`, como haría Roble).
  void patchProject(String projectId, Map<String, dynamic> fields) {
    final i = projects.indexWhere((r) => r['_id'] == projectId);
    if (i != -1) projects[i] = {...projects[i], ...fields};
  }

  // ─── Proyectos ────────────────────────────────────────────────────────────
  @override
  Future<List<Map<String, dynamic>>> readProjects() async => _copy(projects);

  @override
  Future<List<Map<String, dynamic>>> readProjectsByOwner(
    String ownerId,
  ) async => _copy([
    for (final r in projects)
      if (r['_owner'] == ownerId) r,
  ]);

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async {
    final row = projectRow(id);
    return row == null ? null : Map<String, dynamic>.of(row);
  }

  @override
  Future<Map<String, dynamic>> createProject(
    Map<String, dynamic> projectData,
  ) async {
    final row = <String, dynamic>{
      '_id': _nextId('proj-nuevo'),
      '_owner': currentUserId,
      ...projectData,
    };
    projects.add(row);
    members.add({
      '_id': _nextId('member'),
      'project_id': row['_id'],
      'user_id': currentUserId,
      'role': {'name': 'owner'},
      'status': 'active',
      'joinedAt': DateTime.now().toUtc().toIso8601String(),
    });
    return Map.of(row);
  }

  @override
  Future<Map<String, dynamic>> updateProject(
    String projectId,
    Map<String, dynamic> fields,
  ) async {
    final i = projects.indexWhere((r) => r['_id'] == projectId);
    if (i == -1) throw StateError('Proyecto $projectId no existe');
    projects[i] = {...projects[i], ...fields};
    return Map.of(projects[i]);
  }

  // ─── Solicitudes ──────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> createJoinRequest(
    Map<String, dynamic> joinRequestData,
  ) async {
    final userId = (joinRequestData['user_id'] ?? currentUserId).toString();
    final row = <String, dynamic>{
      '_id': _nextId('solicitud'),
      '_owner': userId,
      'user_id': userId,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      ...joinRequestData,
    };
    joinRequests.add(row);
    return Map.of(row);
  }

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(
    String userId,
  ) async => _copy([
    for (final r in joinRequests)
      if (r['user_id'] == userId || r['_owner'] == userId) r,
  ]);

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsForProject(
    String projectId,
  ) async => _copy(joinRequestsOf(projectId));

  @override
  Future<Map<String, dynamic>> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    final i = joinRequests.indexWhere((r) => r['_id'] == requestId);
    if (i == -1) throw StateError('Solicitud $requestId no existe');
    joinRequests[i] = {
      ...joinRequests[i],
      'status': {'state': status},
      'reviewed_by': reviewedBy,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'reviewNote': ?reviewNote,
    };
    return Map.of(joinRequests[i]);
  }

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async =>
      profiles[userId];

  // ─── Miembros ─────────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  }) async {
    final existing = members.where(
      (m) =>
          m['project_id'] == projectId &&
          m['user_id'] == userId &&
          (m['status'] ?? 'active') == 'active',
    );
    if (existing.isNotEmpty) return Map.of(existing.first);
    final row = <String, dynamic>{
      '_id': _nextId('member'),
      'project_id': projectId,
      'user_id': userId,
      'role': role ?? {'name': 'member'},
      'status': 'active',
      'joinedAt': DateTime.now().toUtc().toIso8601String(),
    };
    members.add(row);
    return Map.of(row);
  }

  @override
  Future<List<Map<String, dynamic>>> readProjectMembers({
    String? projectId,
  }) async => _copy([
    for (final m in members)
      if (projectId == null || projectId.isEmpty || m['project_id'] == projectId)
        m,
  ]);

  @override
  Future<int> endMembership(
    String projectId,
    String userId,
    String status,
  ) async {
    var ended = 0;
    for (var i = 0; i < members.length; i++) {
      final m = members[i];
      if (m['project_id'] == projectId &&
          m['user_id'] == userId &&
          (m['status'] ?? 'active') == 'active') {
        members[i] = {
          ...m,
          'status': status,
          'leftAt': DateTime.now().toUtc().toIso8601String(),
        };
        ended++;
      }
    }
    return ended;
  }

  @override
  Future<List<Map<String, dynamic>>> readMembershipsByUser(
    String userId,
  ) async => _copy([
    for (final m in members)
      if (m['user_id'] == userId) m,
  ]);

  @override
  Future<List<Map<String, dynamic>>> readProjectsParticipatedBy(
    String userId,
  ) async {
    final ids = {
      for (final m in members)
        if (m['user_id'] == userId) m['project_id'],
    };
    return _copy([
      for (final p in projects)
        if (ids.contains(p['_id'])) p,
    ]);
  }

  // ─── Guardados ────────────────────────────────────────────────────────────
  @override
  Future<List<Map<String, dynamic>>> readSavedByUser(String userId) async =>
      _copy([
        for (final r in saved)
          if (r['user_id'] == userId) r,
      ]);

  @override
  Future<Map<String, dynamic>> createSaved({
    required String userId,
    required String projectId,
  }) async {
    final existing = saved.where(
      (r) => r['user_id'] == userId && r['project_id'] == projectId,
    );
    if (existing.isNotEmpty) return Map.of(existing.first);
    final row = <String, dynamic>{
      '_id': _nextId('guardado'),
      '_owner': userId,
      'user_id': userId,
      'project_id': projectId,
    };
    saved.add(row);
    return Map.of(row);
  }

  @override
  Future<void> deleteSaved({
    required String userId,
    required String projectId,
  }) async {
    saved.removeWhere(
      (r) => r['user_id'] == userId && r['project_id'] == projectId,
    );
  }

  // ─── Invitaciones ─────────────────────────────────────────────────────────
  @override
  Future<List<Map<String, dynamic>>> findUsersByEmails(
    List<String> emails,
  ) async => const [];

  @override
  Future<List<Map<String, dynamic>>> createInvitations(
    List<Map<String, dynamic>> rows,
  ) async {
    final inserted = [
      for (final r in rows) {'_id': _nextId('invitacion'), ...r},
    ];
    invitations.addAll(inserted);
    return _copy(inserted);
  }

  @override
  Future<List<Map<String, dynamic>>> readInvitationsForUser(
    String userId,
  ) async => _copy([
    for (final r in invitations)
      if (r['user_id'] == userId) r,
  ]);

  @override
  Future<Map<String, dynamic>> updateInvitationStatus({
    required String invitationId,
    required String status,
  }) async {
    final i = invitations.indexWhere((r) => r['_id'] == invitationId);
    if (i == -1) throw StateError('Invitación $invitationId no existe');
    invitations[i] = {
      ...invitations[i],
      'status': status,
      'respondedAt': DateTime.now().toUtc().toIso8601String(),
    };
    return Map.of(invitations[i]);
  }

  @override
  Future<void> deleteProjectCascade(String projectId) async {
    invitations.removeWhere((r) => r['project_id'] == projectId);
    members.removeWhere((r) => r['project_id'] == projectId);
    saved.removeWhere((r) => r['project_id'] == projectId);
    projects.removeWhere((r) => r['_id'] == projectId);
  }
}
