import 'dart:convert';
import 'package:roble/roble.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/core/utils/string_list.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_join_request.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import '../datasources/i_project_data_source.dart';

class ProjectRepository implements IProjectRepository {
  ProjectRepository(this._source);

  final IProjectDataSource _source;

  @override
  Future<List<Project>> getProjects() async {
    final rows = await _guard(() => _source.readProjects());
    final membersMap = await _getMembersMap();
    return rows.map((r) => _toProject(r, membersMap)).toList();
  }

  @override
  Future<List<Project>> getProjectsByOwner(String ownerId) async {
    final rows = await _guard(() => _source.readProjectsByOwner(ownerId));
    final membersMap = await _getMembersMap();
    return rows.map((r) => _toProject(r, membersMap)).toList();
  }


  @override
  Future<Project?> getProjectById(String id) async {
    final row = await _guard(() => _source.readProjectById(id));
    if (row == null) return null;
    final membersMap = await _getMembersMap(projectId: id);
    return _toProject(row, membersMap);
  }

  @override
  Future<Project> createProject({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
    String imageUrl = '',
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'jobs': jobs,
      'skills': skills,
      'status': 'open',
    };

    final resultRow = await _guard(() => _source.createProject(payload));
    final createdId = (resultRow['_id'] ?? resultRow['id'])?.toString() ?? '';
    final membersMap = await _getMembersMap(projectId: createdId);
    return _toProject(resultRow, membersMap);
  }

  @override
  Future<ProjectJoinRequest> createJoinRequest({
    required String projectId,
    String? userId,
    dynamic status,
  }) async {
    final payload = <String, dynamic>{
      'project_id': projectId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'status': status ?? 'pending',
    };

    final resultRow = await _guard(() => _source.createJoinRequest(payload));
    return _toProjectJoinRequest(resultRow);
  }

  @override
  Future<List<ProjectJoinRequest>> getJoinRequestsByUser(String userId) async {
    final rows = await _guard(() => _source.readJoinRequestsByUser(userId));
    return rows.map(_toProjectJoinRequest).toList();
  }

  @override
  Future<List<ProjectJoinRequest>> getJoinRequestsForProject(String projectId) async {
    final rows = await _guard(() => _source.readJoinRequestsForProject(projectId));
    return rows.map(_toProjectJoinRequest).toList();
  }

  @override
  Future<ProjectJoinRequest> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    final resultRow = await _guard(
      () => _source.updateJoinRequestStatus(
        requestId: requestId,
        status: status,
        reviewedBy: reviewedBy,
        reviewNote: reviewNote,
      ),
    );
    return _toProjectJoinRequest(resultRow);
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _guard(() => _source.readUserProfile(userId));
  }

  @override
  Future<void> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  }) async {
    await _guard(
      () => _source.addProjectMember(
        projectId: projectId,
        userId: userId,
        role: role,
      ),
    );
  }




  // ─── Traducción de errores ────────────────────────────────────────────────
  // Las excepciones se atrapan de más específica a más general; si no se
  // respeta el orden, RobleApiException (clase base) absorbería todo lo demás.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RobleApiNetworkException {
      throw const ProjectFailure('Sin conexión. Verifica tu red.');
    } on RobleApiTimeoutException {
      throw const ProjectFailure('La solicitud tardó demasiado. Intenta de nuevo.');
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 403) throw const ProjectFailure('No tienes permiso para ver esto.');
      if (e.statusCode == 404) throw const ProjectFailure('No se encontró el proyecto.');
      // Para 400 y otros, mostrar el mensaje real del servidor para facilitar diagnóstico.
      final msg = e.message.isNotEmpty ? e.message : 'Error HTTP ${e.statusCode}';
      throw ProjectFailure(msg);
    } on RobleApiException catch (e) {
      final msg = e.message.isNotEmpty ? e.message : 'Error desconocido del servidor';
      throw ProjectFailure(msg);
    }
  }

  Future<Map<String, List<String>>> _getMembersMap({String? projectId}) async {
    final Map<String, List<String>> map = {};
    try {
      final memberRows = await _source.readProjectMembers(projectId: projectId);
      for (final row in memberRows) {
        final pId = (row['project_id'] ?? row['projectId'])?.toString() ?? '';
        final uId = (row['user_id'] ?? row['userId'] ?? row['_owner'])?.toString() ?? '';
        if (pId.isEmpty) continue;

        final role = row['role'];
        String roleName = '';
        if (role is Map) {
          roleName = (role['name'] ?? '').toString();
        } else if (role is String) {
          roleName = role;
        }

        String displayName;
        if (roleName == 'owner' || roleName == 'creador') {
          displayName = 'Creador del proyecto';
        } else if (roleName.isNotEmpty) {
          displayName = 'Colaborador ($roleName)';
        } else {
          displayName = uId.length > 8 ? 'Usuario ${uId.substring(0, 8)}' : 'Miembro';
        }

        map.putIfAbsent(pId, () => []).add(displayName);
      }
    } catch (_) {}
    return map;
  }

  // ─── Mappers ──────────────────────────────────────────────────────────────
  Project _toProject(Map<String, dynamic> row, [Map<String, List<String>>? membersMap]) {
    final id = (row['_id'] ?? row['id'])?.toString() ?? '';
    final owner = (row['_owner'] ?? row['owner'] ?? row['user_id'])?.toString() ?? '';

    List<String> membersList = membersMap?[id] ?? [];
    if (membersList.isEmpty) {
      if (id == DummyData.kircheId) {
        membersList = DummyData.kircheProject.members;
      } else if (id == DummyData.solariaId) {
        membersList = DummyData.solariaProject.members;
      } else {
        membersList = ['Creador del proyecto'];
      }
    }

    return Project(
      id: id,
      owner: owner,
      title: (row['title'] ?? '') as String,
      imageUrl: (row['imageUrl'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      jobs: decodeStringList(row['jobs']),
      skills: decodeStringList(row['skills']),
      status: (row['status'] as String?) ?? 'open',
      members: membersList,
    );
  }

  ProjectJoinRequest _toProjectJoinRequest(Map<String, dynamic> row) {
    Map<String, dynamic> parsedStatus = {};
    final rawStatus = row['status'];
    if (rawStatus is Map<String, dynamic>) {
      parsedStatus = rawStatus;
    } else if (rawStatus is Map) {
      parsedStatus = Map<String, dynamic>.from(rawStatus);
    } else if (rawStatus is String) {
      try {
        final decoded = jsonDecode(rawStatus);
        if (decoded is Map<String, dynamic>) {
          parsedStatus = decoded;
        } else if (decoded is Map) {
          parsedStatus = Map<String, dynamic>.from(decoded);
        } else {
          parsedStatus = {'state': rawStatus};
        }
      } catch (_) {
        parsedStatus = {'state': rawStatus};
      }
    }

    return ProjectJoinRequest(
      id: (row['_id'] ?? row['id'])?.toString() ?? '',
      userId: (row['user_id'] ?? row['_owner'])?.toString() ?? '',
      projectId: (row['project_id'])?.toString() ?? '',
      status: parsedStatus,
      createdAt: row['createdAt'] != null ? DateTime.tryParse(row['createdAt'].toString()) : null,
      updatedAt: row['updatedAt'] != null ? DateTime.tryParse(row['updatedAt'].toString()) : null,
      reviewedBy: row['reviewed_by']?.toString(),
      reviewNote: row['reviewNote']?.toString(),
      owner: row['_owner']?.toString(),
    );
  }
}
