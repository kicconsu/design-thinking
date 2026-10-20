import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/discover/data/local_discover_repository.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';

void main() {
  final repo = LocalDiscoverRepository(
    ProjectRepository(InMemoryProjectDataSource()),
  );

  test('pagina sin filtros y reporta el total', () async {
    final first = await repo.getPage(
      filter: ProjectFilter.none,
      offset: 0,
      limit: 2,
    );
    final rest = await repo.getPage(
      filter: ProjectFilter.none,
      offset: 2,
      limit: 2,
    );

    expect(first.projects.length, 2);
    expect(first.total, rest.total);
    expect(first.projects.length + rest.projects.length, first.total);
  });

  test(
    'las opciones salen de los proyectos y la carrera elegida filtra',
    () async {
      final options = await repo.getOptions(ProjectFilter.none);
      expect(options.careers, isNotEmpty);

      final career = options.careers.first;
      final page = await repo.getPage(
        filter: ProjectFilter(career: career.key),
        offset: 0,
        limit: 50,
      );
      expect(page.total, career.count);
    },
  );
}
