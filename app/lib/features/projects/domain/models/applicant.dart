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

  /// Índice general de compromiso, 0-100; 0 si no tiene historial. Es lo único
  /// de sus indicadores que muestra la lista: el resto se ve en su ficha.
  /// Índice general de compromiso; nulo si no tiene historial.
  final int? commitmentScore;

  const Applicant({
    required this.id,
    required this.projectId,
    this.userId = '',
    required this.name,
    required this.academicInfo,
    required this.appliedAgo,
    this.statusState = 'pending',
    this.commitmentScore,
  });
}
