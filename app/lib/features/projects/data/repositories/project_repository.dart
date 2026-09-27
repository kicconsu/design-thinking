import 'package:roble/roble.dart';

import 'package:imker/core/utils/string_list.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import '../datasources/i_project_data_source.dart';

class ProjectRepository implements IProjectRepository {
  ProjectRepository(this._source);

  final IProjectDataSource _source;

  @override
  Future<List<Project>> getProjects() async {
    final rows = await _guard(() => _source.readProjects());
    return rows.map(_toProject).toList();
  }

  @override
  Future<List<Project>> getProjectsByOwner(String ownerId) async {
    final rows = await _guard(() => _source.readProjectsByOwner(ownerId));
    return rows.map(_toProject).toList();
  }


  @override
  Future<Project?> getProjectById(String id) async {
    final row = await _guard(() => _source.readProjectById(id));
    return row == null ? null : _toProject(row);
  }

  @override
  Future<Project> createProject({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
    String imageUrl = '',
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'jobs': jobs,
      'skills': skills,
      'status': 'open',
    };

    final resultRow = await _guard(() => _source.createProject(payload));
    return _toProject(resultRow);
  }


  // ─── Traducción de errores ────────────────────────────────────────────────
  // Las excepciones se atrapan de más específica a más general; si no se
  // respeta el orden, RobleApiException (clase base) absorbería todo lo demás.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RobleApiNetworkException {
      throw const ProjectFailure('Sin conexión. Verifica tu red.');
    } on RobleApiTimeoutException {
      throw const ProjectFailure('La solicitud tardó demasiado. Intenta de nuevo.');
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 403) throw const ProjectFailure('No tienes permiso para ver esto.');
      if (e.statusCode == 404) throw const ProjectFailure('No se encontró el proyecto.');
      throw ProjectFailure(e.message);
    } on RobleApiException catch (e) {
      throw ProjectFailure(e.message);
    }
  }

  // ─── Mapper ───────────────────────────────────────────────────────────────
  Project _toProject(Map<String, dynamic> row) => Project(
    id: (row['_id'] ?? row['id'])?.toString() ?? '',
    owner: (row['_owner'] ?? row['owner'] ?? row['user_id'])?.toString() ?? '',
    title: (row['title'] ?? '') as String,
    imageUrl: (row['imageUrl'] as String?) ?? '',
    description: (row['description'] as String?) ?? '',
    // jobs y skills son columnas jsonb: un array en la raíz de la columna.
    jobs: decodeStringList(row['jobs']),
    skills: decodeStringList(row['skills']),
    status: (row['status'] as String?) ?? 'open',
  );
}
