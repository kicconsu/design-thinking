import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/domain/models/project_page.dart';

abstract class IDiscoverRepository {
  /// Hasta [limit] proyectos que cumplen [filter], desde [offset], del más
  /// reciente al más antiguo. Lanza `ProjectFailure`.
  Future<ProjectPage> getPage({
    required ProjectFilter filter,
    required int offset,
    required int limit,
  });

  /// Carreras y habilidades que ofrecen los selectores con [filter] aplicado:
  /// las carreras no dependen de la habilidad elegida; las habilidades, de la
  /// carrera. Lanza `ProjectFailure`.
  Future<FilterOptions> getOptions(ProjectFilter filter);
}
