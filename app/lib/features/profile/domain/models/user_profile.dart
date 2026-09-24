/// Entidad de dominio: el perfil del usuario (pestaña "Perfil").
///
/// [name] viene de la sesión de autenticación, no de esta entidad — el
/// perfil solo guarda lo que el propio usuario puede editar (resumen y
/// habilidades) más su información académica.
class UserProfile {
  const UserProfile({
    this.academicInfo = '',
    this.bio = '',
    this.skills = const [],
    // Los indicadores de confianza todavía no tienen un algoritmo real
    // detrás; por ahora son un valor fijo hasta que el equipo defina cómo
    // calcularlos a partir del historial de colaboración.
    this.commitmentScore = 0,
    this.onTimeScore = 0,
    this.responseRateScore = 0,
    this.completedProjectsScore = 0,
  });

  final String academicInfo;
  final String bio;
  final List<String> skills;
  final int commitmentScore;
  final int onTimeScore;
  final int responseRateScore;
  final int completedProjectsScore;

  UserProfile copyWith({String? bio, List<String>? skills}) => UserProfile(
    academicInfo: academicInfo,
    bio: bio ?? this.bio,
    skills: skills ?? this.skills,
    commitmentScore: commitmentScore,
    onTimeScore: onTimeScore,
    responseRateScore: responseRateScore,
    completedProjectsScore: completedProjectsScore,
  );
}
