/// Entidad de dominio: el perfil del usuario (pestaña "Perfil").
///
/// [name] viene de la sesión de autenticación, no de esta entidad — el
/// perfil solo guarda lo que el propio usuario puede editar (resumen,
/// habilidades y carrera).
class UserProfile {
  const UserProfile({
    this.name = '',
    this.program = '',
    this.institution = '',
    this.bio = '',
    this.skills = const [],
    // Los indicadores de confianza salen del historial de colaboración (ver
    // `features/trust`). Nulo es "sin datos", no 0 %.
    this.hasTrustHistory = false,
    this.commitmentScore,
    this.onTimeScore,
    this.fulfillmentScore,
    this.completedProjectsScore,
  });

  /// Nombre guardado en la fila de `profile`. En el perfil propio el nombre de
  /// pantalla sale de la sesión; esto sirve para mostrar a otras personas.
  final String name;
  final String program;
  final String institution;
  final String bio;
  final List<String> skills;
  final bool hasTrustHistory;
  final int? commitmentScore;
  final int? onTimeScore;
  final int? fulfillmentScore;
  final int? completedProjectsScore;

  /// "Programa - Institución", o lo que haya de los dos.
  String get academicInfo {
    if (program.isEmpty) return institution;
    if (institution.isEmpty) return program;
    return '$program - $institution';
  }

  /// Hay datos suficientes para presentarse: carrera y al menos una habilidad.
  /// La descripción es opcional.
  bool get isComplete => program.isNotEmpty && skills.isNotEmpty;

  UserProfile copyWith({
    String? program,
    String? institution,
    String? bio,
    List<String>? skills,
    bool? hasTrustHistory,
    int? commitmentScore,
    int? onTimeScore,
    int? fulfillmentScore,
    int? completedProjectsScore,
  }) => UserProfile(
    name: name,
    program: program ?? this.program,
    institution: institution ?? this.institution,
    bio: bio ?? this.bio,
    skills: skills ?? this.skills,
    hasTrustHistory: hasTrustHistory ?? this.hasTrustHistory,
    commitmentScore: commitmentScore ?? this.commitmentScore,
    onTimeScore: onTimeScore ?? this.onTimeScore,
    fulfillmentScore: fulfillmentScore ?? this.fulfillmentScore,
    completedProjectsScore:
        completedProjectsScore ?? this.completedProjectsScore,
  );
}
