/// Una solicitud de colaboración de una persona para un proyecto co-creado.
///
/// Solo lo que se sabe de la solicitud y quien la hizo; el perfil completo se
/// lee al abrir su ficha.
class Applicant {
  final String id;
  final String projectId;
  final String userId;
  final String name;

  /// "Programa - Institución" del perfil; vacío si no lo llenó.
  final String academicInfo;
  final String appliedAgo;
  final String statusState;

  const Applicant({
    required this.id,
    required this.projectId,
    this.userId = '',
    required this.name,
    required this.academicInfo,
    required this.appliedAgo,
    this.statusState = 'pending',
  });
}
