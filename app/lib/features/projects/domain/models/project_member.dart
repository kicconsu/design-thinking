/// Papel de una persona dentro de un proyecto (`project_member.role`).
enum ProjectMemberRole {
  owner('Creador'),
  collaborator('Colaborador');

  const ProjectMemberRole(this.label);
  final String label;

  /// Acepta los nombres que ha guardado el equipo en `role.name`. Lo que no se
  /// reconoce cuenta como colaborador: nunca se promueve a nadie a creador por
  /// un valor raro.
  static ProjectMemberRole fromName(String? name) => switch (name) {
    'owner' || 'creador' => ProjectMemberRole.owner,
    _ => ProjectMemberRole.collaborator,
  };
}

/// Entidad del dominio: una persona que está en un proyecto ahora mismo.
class ProjectMember {
  const ProjectMember({
    required this.userId,
    required this.name,
    this.career = '',
    this.role = ProjectMemberRole.collaborator,
    this.joinedAt,
  });

  final String userId;
  final String name;

  /// "Programa - Institución" tomado del perfil; vacío si no lo llenó.
  final String career;
  final ProjectMemberRole role;
  final DateTime? joinedAt;

  bool get isOwner => role == ProjectMemberRole.owner;
}
