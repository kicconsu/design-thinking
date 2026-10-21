import 'package:imker/features/discover/domain/models/filter_option.dart';
import 'package:imker/features/projects/domain/models/project.dart';

/// Una página del feed filtrado. [total] cuenta todos los que cumplen el
/// filtro, no solo los de esta página.
class ProjectPage {
  const ProjectPage({required this.projects, required this.total});

  final List<Project> projects;
  final int total;
}

/// Opciones de los selectores para un filtro dado.
class FilterOptions {
  const FilterOptions({this.careers = const [], this.skills = const []});

  final List<FilterOption> careers;
  final List<FilterOption> skills;
}
