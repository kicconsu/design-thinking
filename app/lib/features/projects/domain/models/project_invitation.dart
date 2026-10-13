/// Invitación a unirse a un proyecto (`project_invitation`).
class ProjectInvitation {
  const ProjectInvitation({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.email,
    required this.status,
    this.createdAt,
    this.respondedAt,
    this.invitedBy,
  });

  final String id;
  final String projectId;
  final String userId;
  final String email;

  /// `pending`, `accepted` o `declined`.
  final String status;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  /// `_owner` de la fila: quien invitó.
  final String? invitedBy;

  bool get isPending => status == 'pending';
}
