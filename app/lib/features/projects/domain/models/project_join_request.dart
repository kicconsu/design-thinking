import 'dart:convert';

/// Entidad del dominio: una solicitud para unirse a un proyecto (`project_join_request`).
class ProjectJoinRequest {
  const ProjectJoinRequest({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.reviewedBy,
    this.reviewNote,
    this.owner,
  });

  final String id;
  final String userId;
  final String projectId;
  final Map<String, dynamic> status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? reviewedBy;
  final String? reviewNote;
  final String? owner;

  /// Retorna el estado en formato legible de texto.
  String get statusState {
    if (status.containsKey('state')) return status['state'].toString();
    if (status.containsKey('status')) return status['status'].toString();
    if (status.containsKey('value')) return status['value'].toString();
    return jsonEncode(status);
  }

  @override
  String toString() =>
      'ProjectJoinRequest(id: $id, userId: $userId, projectId: $projectId, status: $status)';
}
