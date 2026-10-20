import 'dart:async';

import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/domain/models/project_page.dart';
import 'package:imker/features/discover/domain/project_filter_index.dart';
import 'package:imker/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/project_failure.dart';

/// Repositorio de Descubrir para pruebas: filtra [projects] con la misma
/// lógica pura que el modo mock. Con [failure] todo lanza; con [gate] las
/// respuestas esperan a que la prueba las libere.
class FakeDiscoverRepository implements IDiscoverRepository {
  FakeDiscoverRepository(this.projects);

  List<Project> projects;
  ProjectFailure? failure;
  Completer<void>? gate;

  /// Cada página pedida, en orden.
  final pagesAsked = <({ProjectFilter filter, int offset, int limit})>[];
  final optionsAsked = <ProjectFilter>[];

  @override
  Future<ProjectPage> getPage({
    required ProjectFilter filter,
    required int offset,
    required int limit,
  }) async {
    pagesAsked.add((filter: filter, offset: offset, limit: limit));
    await gate?.future;
    if (failure != null) throw failure!;
    final matches = ProjectFilterIndex(projects).apply(filter);
    return ProjectPage(
      projects: matches.skip(offset).take(limit).toList(),
      total: matches.length,
    );
  }

  @override
  Future<FilterOptions> getOptions(ProjectFilter filter) async {
    optionsAsked.add(filter);
    await gate?.future;
    if (failure != null) throw failure!;
    final index = ProjectFilterIndex(projects);
    return FilterOptions(
      careers: index.careerOptions(filter),
      skills: index.skillOptions(filter),
    );
  }
}
