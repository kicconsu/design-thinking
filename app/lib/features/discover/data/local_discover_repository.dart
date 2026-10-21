import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/domain/models/project_page.dart';
import 'package:imker/features/discover/domain/project_filter_index.dart';
import 'package:imker/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

/// Filtra y pagina en memoria sobre lo que devuelve [IProjectRepository]. Es el
/// camino del modo mock y la referencia de las consultas guardadas.
class LocalDiscoverRepository implements IDiscoverRepository {
  LocalDiscoverRepository(this._projects);

  final IProjectRepository _projects;

  Future<ProjectFilterIndex> _index() async =>
      ProjectFilterIndex(await _projects.getProjects());

  @override
  Future<ProjectPage> getPage({
    required ProjectFilter filter,
    required int offset,
    required int limit,
  }) async {
    final matches = (await _index()).apply(filter);
    return ProjectPage(
      projects: matches.skip(offset).take(limit).toList(),
      total: matches.length,
    );
  }

  @override
  Future<FilterOptions> getOptions(ProjectFilter filter) async {
    final index = await _index();
    return FilterOptions(
      careers: index.careerOptions(filter),
      skills: index.skillOptions(filter),
    );
  }
}
