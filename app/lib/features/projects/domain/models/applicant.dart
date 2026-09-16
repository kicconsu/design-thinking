/// Un proyecto (terminado o en curso) que el aspirante reporta en su
/// historial, mostrado en la pestaña "Proyectos" del detalle de la solicitud.
class ApplicantProjectExperience {
  final String title;
  final String status; // 'Completado', 'Incompleto', 'En Desarrollo'
  final String description;
  final double peerEvaluation; // sobre 5.0

  const ApplicantProjectExperience({
    required this.title,
    required this.status,
    required this.description,
    required this.peerEvaluation,
  });
}

/// Una solicitud de colaboración de una persona para un proyecto co-creado.
class Applicant {
  final String id;
  final String projectId;
  final String name;
  final String academicInfo;
  final String requestedRole;
  final String appliedAgo;
  final int commonProjects;
  final int commitmentScore; // Índice general de compromiso, 0-100
  final int onTimeScore;
  final int responseRateScore;
  final int completedProjectsScore;
  final String bio;
  final List<String> skills;
  final List<ApplicantProjectExperience> experience;

  const Applicant({
    required this.id,
    required this.projectId,
    required this.name,
    required this.academicInfo,
    required this.requestedRole,
    required this.appliedAgo,
    required this.commonProjects,
    required this.commitmentScore,
    required this.onTimeScore,
    required this.responseRateScore,
    required this.completedProjectsScore,
    required this.bio,
    required this.skills,
    required this.experience,
  });
}
