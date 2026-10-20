import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/core/utils/error_message.dart';
import 'package:imker/core/utils/string_list.dart';
import 'package:imker/features/discover/domain/models/filter_option.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/domain/models/project_page.dart';
import 'package:imker/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/project_failure.dart';

/// Filtra y pagina en el servidor con las consultas guardadas
/// `proyectos_filtrados` y `opciones_filtros_proyectos` (`docs/db/saved_queries.sql`).
class RobleDiscoverRepository implements IDiscoverRepository {
  RobleDiscoverRepository(this._client);

  final RobleClient _client;

  @override
  Future<ProjectPage> getPage({
    required ProjectFilter filter,
    required int offset,
    required int limit,
  }) async {
    final rows = await _run('proyectos_filtrados', [
      filter.career ?? '',
      filter.skill ?? '',
      filter.onlyOpen.toString(),
      limit,
      offset,
    ]);
    return ProjectPage(
      projects: rows.map(_toProject).toList(),
      total: rows.isEmpty ? 0 : _int(rows.first['total']),
    );
  }

  @override
  Future<FilterOptions> getOptions(ProjectFilter filter) async {
    final rows = await _run('opciones_filtros_proyectos', [
      filter.career ?? '',
      filter.onlyOpen.toString(),
    ]);
    List<FilterOption> of(String kind) => [
      for (final r in rows)
        if (r['kind'] == kind)
          FilterOption(
            key: r['key'].toString(),
            label: r['label'].toString(),
            count: _int(r['project_count']),
          ),
    ];
    return FilterOptions(careers: of('career'), skills: of('skill'));
  }

  Future<List<Map<String, dynamic>>> _run(
    String name,
    List<Object> params,
  ) async {
    try {
      final result = await _client.db.executeQueryByName(name, params: params);
      return [
        for (final row in result.rows)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    } catch (e) {
      throw ProjectFailure(errorMessage(e));
    }
  }

  // Roble devuelve los conteos (bigint) y los numeric como texto.
  int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

  Project _toProject(Map<String, dynamic> row) {
    final progress = double.tryParse(row['progress']?.toString() ?? '') ?? 0;
    return Project(
      id: row['_id']?.toString() ?? '',
      owner: row['_owner']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      imageUrl: row['imageUrl']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      jobs: decodeStringList(row['jobs']),
      skills: decodeStringList(row['skills']),
      status: row['status']?.toString() ?? 'open',
      memberCount: _int(row['member_count']),
      progress: progress.clamp(0, 100).toDouble(),
    );
  }
}
