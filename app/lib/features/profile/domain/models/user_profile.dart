/// Entidad de dominio: el perfil del usuario (pestaña "Perfil").
///
/// [name] viene de la sesión de autenticación, no de esta entidad — el
/// perfil solo guarda lo que el propio usuario puede editar (resumen,
/// habilidades y carrera).
class UserProfile {
  const UserProfile({
    this.program = '',
    this.institution = '',
    this.bio = '',
    this.skills = const [],
    // Los indicadores de confianza salen del historial de colaboración, que
    // todavía no existe: sin historial valen 0 y no se muestran.
    this.commitmentScore = 0,
    this.onTimeScore = 0,
    this.responseRateScore = 0,
    this.completedProjectsScore = 0,
  });

  final String program;
  final String institution;
  final String bio;
  final List<String> skills;
  final int commitmentScore;
  final int onTimeScore;
  final int responseRateScore;
  final int completedProjectsScore;

  /// "Programa - Institución", o lo que haya de los dos.
  String get academicInfo {
    if (program.isEmpty) return institution;
    if (institution.isEmpty) return program;
    return '$program - $institution';
  }

  /// Hay datos suficientes para presentarse: carrera y al menos una habilidad.
  /// La descripción es opcional.
  bool get isComplete => program.isNotEmpty && skills.isNotEmpty;

  /// Mismo criterio que las solicitudes (`Applicant`): sin historial no hay
  /// indicadores que mostrar.
  bool get hasTrustHistory => commitmentScore > 0;

  UserProfile copyWith({
    String? program,
    String? institution,
    String? bio,
    List<String>? skills,
  }) => UserProfile(
    program: program ?? this.program,
    institution: institution ?? this.institution,
    bio: bio ?? this.bio,
    skills: skills ?? this.skills,
    commitmentScore: commitmentScore,
    onTimeScore: onTimeScore,
    responseRateScore: responseRateScore,
    completedProjectsScore: completedProjectsScore,
  );
}
