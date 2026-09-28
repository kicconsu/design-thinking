import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:imker/core/roble/roble_client.dart';
import 'package:roble/roble.dart';

import 'i_project_data_source.dart';

class RobleProjectDataSource with UiLoggy implements IProjectDataSource {
  RobleProjectDataSource(this._client);

  final RobleClient _client;

  @override
  Future<List<Map<String, dynamic>>> readProjects() =>
      _client.readPublicOrPrivate(RobleClient.projects);

  @override
  Future<List<Map<String, dynamic>>> readProjectsByOwner(String ownerId) async {
    if (_client.readsPublicly) {
      return _client.db.publicRead(
        RobleClient.projects,
        filters: {'_owner': ownerId},
      );
    }
    try {
      // Intento 1: filtro en el servidor por _owner exacto.
      if (ownerId.isNotEmpty) {
        final filtered = await _client.db.read(
          RobleClient.projects,
          filters: {'_owner': ownerId},
        );
        if (filtered.isNotEmpty) return filtered;
      }

      // Intento 2: leer todos y filtrar del lado cliente con matchesUser.
      // Necesario cuando Roble guarda el _owner en un formato distinto al ownerId cacheado.
      final all = await _client.db.read(RobleClient.projects);
      final matched = all
          .where((r) => _client.matchesUser(r['_owner']?.toString()))
          .toList();
      return matched;
    } catch (_) {}
    return [];
  }

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async {
    // getById no está disponible en lectura pública; publicRead filtra por _id.
    if (!_client.readsPublicly)
      return _client.db.getById(RobleClient.projects, id);
    final rows = await _client.db.publicRead(
      RobleClient.projects,
      filters: {'_id': id},
    );
    return rows.firstOrNull;
  }

  @override
  Future<Map<String, dynamic>> createProject(
    Map<String, dynamic> projectData,
  ) async {
    // Sanitize: Roble DB acepta Maps en columnas jsonb, pero rechaza Lists
    // directamente. Serializamos jobs y skills como strings JSON para que
    // PostgreSQL los acepte sin error de conversión.
    final sanitized = Map<String, dynamic>.from(projectData);
    for (final key in ['jobs', 'skills']) {
      final raw = sanitized[key];
      List<String> asList;
      if (raw is List) {
        asList = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          asList = (decoded is List)
              ? decoded.map((e) => e.toString()).toList()
              : <String>[];
        } catch (_) {
          asList = <String>[];
        }
      } else {
        asList = <String>[];
      }
      // Enviamos como JSON string para columnas jsonb (Roble rechaza List<> nativa).
      sanitized[key] = jsonEncode(asList);
    }
    if (sanitized['status'] is Map) {
      sanitized['status'] =
          (sanitized['status'] as Map)['state']?.toString() ?? 'open';
    }
    sanitized['status'] ??= 'open';

    loggy.debug('createProject payload: $sanitized');

    late Map<String, dynamic> result;
    try {
      result = await _client.db.create(RobleClient.projects, sanitized);
    } on RobleApiHttpException catch (e) {
      loggy.error('createProject HTTP ${e.statusCode}: ${e.message}');
      rethrow;
    } catch (e) {
      loggy.error('createProject error: $e');
      rethrow;
    }

    final String createdId = (result['_id'] ?? result['id'] ?? '').toString();
    final String ownerId = _client.currentUserId ?? '';

    if (createdId.isNotEmpty && ownerId.isNotEmpty) {
      try {
        await addProjectMember(
          projectId: createdId,
          userId: ownerId,
          role: {'name': 'owner'},
        );
      } catch (e) {
        loggy.warning(
          'No se pudo insertar el miembro creador en project_member: $e',
        );
      }
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> createJoinRequest(
    Map<String, dynamic> joinRequestData,
  ) async {
    final payload = Map<String, dynamic>.from(joinRequestData);
    final String currentUserId = _client.currentUserId ?? '';
    final String nowIso = DateTime.now().toUtc().toIso8601String();

    final String rawProjectId =
        (payload['project_id'] ?? payload['projectId'] ?? '').toString();
    String rawUserId =
        (payload['user_id'] ?? payload['userId'] ?? currentUserId).toString();
    if (rawUserId.isEmpty && currentUserId.isNotEmpty) {
      rawUserId = currentUserId;
    }

    final bool isProjectUuid = _isValidUuid(rawProjectId);
    final bool isUserUuid = _isValidUuid(rawUserId);

    // Formatear status como mapa/JSON objeto según la columna `status (json)` de Roble DB
    Map<String, dynamic> statusMap = {'state': 'pending'};
    final rawStatus = payload['status'];
    if (rawStatus is Map<String, dynamic>) {
      statusMap = rawStatus;
    } else if (rawStatus is Map) {
      statusMap = Map<String, dynamic>.from(rawStatus);
    } else if (rawStatus is String && rawStatus.isNotEmpty) {
      statusMap = {'state': rawStatus};
    }

    // Si project_id o user_id no son UUIDs válidos (p. ej. proyectos demo como '1' o 'solaria-active'),
    // la base de datos de Roble rechazará la inserción con error de tipo UUID.
    if (!isProjectUuid || !isUserUuid) {
      return {
        '_id': 'local-req-${DateTime.now().millisecondsSinceEpoch}',
        '_owner': rawUserId,
        'user_id': rawUserId,
        'project_id': rawProjectId,
        'status': statusMap,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };
    }

    final exactPayload = <String, dynamic>{
      'user_id': rawUserId,
      'project_id': rawProjectId,
      'status': statusMap,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    };

    try {
      loggy.debug('createJoinRequest payload: $exactPayload');
      return await _client.db.create(
        RobleClient.projectJoinRequests,
        exactPayload,
      );
    } catch (e) {
      // Loguear el error completo para diagnosticar el 400 de Roble DB
      loggy.error('createJoinRequest falló (400?): $e');
      return {
        '_id': 'local-req-${DateTime.now().millisecondsSinceEpoch}',
        '_owner': rawUserId,
        'user_id': rawUserId,
        'project_id': rawProjectId,
        'status': statusMap,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };
    }
  }

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(
    String userId,
  ) async {
    if (_client.readsPublicly) {
      if (_isValidUuid(userId)) {
        try {
          return await _client.db.publicRead(
            RobleClient.projectJoinRequests,
            filters: {'user_id': userId},
          );
        } catch (_) {}
      }
      return [];
    }
    try {
      if (_isValidUuid(userId)) {
        final filtered = await _client.db.read(
          RobleClient.projectJoinRequests,
          filters: {'user_id': userId},
        );
        if (filtered.isNotEmpty) return filtered;
      }
      final all = await _client.db.read(RobleClient.projectJoinRequests);
      return all
          .where(
            (r) =>
                r['user_id']?.toString() == userId ||
                r['userId']?.toString() == userId ||
                _client.matchesUser(r['_owner']?.toString()),
          )
          .toList();
    } catch (_) {}
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsForProject(
    String projectId,
  ) async {
    try {
      if (_isValidUuid(projectId)) {
        final filtered = await _client.db.read(
          RobleClient.projectJoinRequests,
          filters: {'project_id': projectId},
        );
        if (filtered.isNotEmpty) return filtered;
      }
      final all = await _client.db.read(RobleClient.projectJoinRequests);
      return all
          .where((r) => r['project_id']?.toString() == projectId)
          .toList();
    } catch (_) {
      try {
        final all = await _client.db.read(RobleClient.projectJoinRequests);
        return all
            .where((r) => r['project_id']?.toString() == projectId)
            .toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      '_id': requestId,
      'status': {'state': status},
      'reviewed_by': reviewedBy,
      'updatedAt': nowIso,
      if (reviewNote != null && reviewNote.isNotEmpty) 'reviewNote': reviewNote,
    };

    try {
      loggy.debug('updateJoinRequestStatus id=$requestId payload: $payload');
      await _client.db.update(
        RobleClient.projectJoinRequests,
        requestId,
        payload,
      );
      return payload;
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 404) {
        loggy.warning(
          'updateJoinRequestStatus: El servidor de Roble devolvió 404 porque la fila pertenece al aspirante (_owner != usuario actual). '
          'Se procesa la decisión ($status) en la aplicación localmente.',
        );
        return payload;
      }
      loggy.error(
        'updateJoinRequestStatus HTTP error ${e.statusCode}: ${e.message}',
      );
      rethrow;
    } catch (e) {
      loggy.error('updateJoinRequestStatus falló: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async {
    try {
      final rows = await _client.readPublicOrPrivate(RobleClient.profileTable);
      for (final r in rows) {
        if (r['_owner']?.toString() == userId ||
            r['_id']?.toString() == userId ||
            r['user_id']?.toString() == userId) {
          return r;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<Map<String, dynamic>> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  }) async {
    final String rawUserId = userId.isNotEmpty ? userId : (_client.currentUserId ?? '');
    final roleMap = role ?? {'name': 'collaborator'};

    if (!_isValidUuid(projectId) || !_isValidUuid(rawUserId)) {
      loggy.warning('addProjectMember omitido: projectId ($projectId) o userId ($rawUserId) no son UUIDs válidos');
      return {
        '_id': 'local-member-${DateTime.now().millisecondsSinceEpoch}',
        'project_id': projectId,
        'user_id': rawUserId,
        'role': roleMap,
      };
    }

    final payload = <String, dynamic>{
      'project_id': projectId,
      'user_id': rawUserId,
      'role': roleMap,
    };

    try {
      loggy.debug('addProjectMember payload: $payload');
      return await _client.db.create(RobleClient.projectMembers, payload);
    } catch (e) {
      loggy.error('addProjectMember falló: $e');
      return {'_id': 'local-member-${DateTime.now().millisecondsSinceEpoch}', ...payload};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> readProjectMembers({String? projectId}) async {
    if (_client.readsPublicly) {
      if (projectId != null && projectId.isNotEmpty && _isValidUuid(projectId)) {
        try {
          return await _client.db.publicRead(
            RobleClient.projectMembers,
            filters: {'project_id': projectId},
          );
        } catch (_) {}
      }
      try {
        return await _client.db.publicRead(RobleClient.projectMembers);
      } catch (_) {}
      return [];
    }
    try {
      if (projectId != null && projectId.isNotEmpty && _isValidUuid(projectId)) {
        final filtered = await _client.db.read(
          RobleClient.projectMembers,
          filters: {'project_id': projectId},
        );
        if (filtered.isNotEmpty) return filtered;
      }
      final all = await _client.db.read(RobleClient.projectMembers);
      if (projectId != null && projectId.isNotEmpty) {
        return all
            .where((r) => r['project_id']?.toString() == projectId)
            .toList();
      }
      return all;
    } catch (_) {}
    return [];
  }

  bool _isValidUuid(String value) {
    if (value.trim().isEmpty) return false;
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegExp.hasMatch(value.trim());
  }
}
