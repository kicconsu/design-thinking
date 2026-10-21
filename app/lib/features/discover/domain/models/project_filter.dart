/// Filtros activos del feed de Descubrir. Carrera y habilidad guardan la clave
/// normalizada (`normalizeLabel`); `null` significa «Todas».
class ProjectFilter {
  const ProjectFilter({this.career, this.skill, this.onlyOpen = false});

  static const none = ProjectFilter();

  final String? career;
  final String? skill;
  final bool onlyOpen;

  int get activeCount =>
      (career != null ? 1 : 0) + (skill != null ? 1 : 0) + (onlyOpen ? 1 : 0);

  bool get isEmpty => activeCount == 0;

  ProjectFilter withCareer(String? career) =>
      ProjectFilter(career: career, skill: skill, onlyOpen: onlyOpen);

  ProjectFilter withSkill(String? skill) =>
      ProjectFilter(career: career, skill: skill, onlyOpen: onlyOpen);

  ProjectFilter withOnlyOpen(bool onlyOpen) =>
      ProjectFilter(career: career, skill: skill, onlyOpen: onlyOpen);

  @override
  bool operator ==(Object other) =>
      other is ProjectFilter &&
      other.career == career &&
      other.skill == skill &&
      other.onlyOpen == onlyOpen;

  @override
  int get hashCode => Object.hash(career, skill, onlyOpen);

  @override
  String toString() =>
      'ProjectFilter(career: $career, skill: $skill, onlyOpen: $onlyOpen)';
}

/// Resultado de ajustar un filtro a las opciones que siguen existiendo.
class FilterReconciliation {
  const FilterReconciliation({
    required this.filter,
    this.droppedCareer = false,
    this.droppedSkill = false,
  });

  final ProjectFilter filter;
  final bool droppedCareer;
  final bool droppedSkill;

  bool get changed => droppedCareer || droppedSkill;
}
