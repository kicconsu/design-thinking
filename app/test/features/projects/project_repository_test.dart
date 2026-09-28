import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/data/datasources/i_project_data_source.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:roble/roble.dart';

class _FailingDataSource implements IProjectDataSource {
  _FailingDataSource(this.exception);
  final Object exception;

  @override
  Future<List<Map<String, dynamic>>> readProjects() async => throw exception;

  @override
  Future<List<Map<String, dynamic>>> readProjectsByOwner(String ownerId) async =>
      throw exception;

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async => throw exception;

  @override
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData) async =>
      throw exception;

  @override
  Future<Map<String, dynamic>> createJoinRequest(Map<String, dynamic> joinRequestData) async =>
      throw exception;

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(String userId) async =>
      throw exception;

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsForProject(String projectId) async =>
      throw exception;

  @override
  Future<Map<String, dynamic>> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async =>
      throw exception;

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async =>
      throw exception;

  @override
  Future<Map<String, dynamic>> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  }) async =>
      throw exception;

  @override
  Future<List<Map<String, dynamic>>> readProjectMembers({String? projectId}) async =>
      throw exception;
}

class _SingleProjectDataSource implements IProjectDataSource {
  _SingleProjectDataSource(this.row);
  final Map<String, dynamic> row;

  @override
  Future<List<Map<String, dynamic>>> readProjects() async => [row];

  @override
  Future<List<Map<String, dynamic>>> readProjectsByOwner(String ownerId) async => [row];

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async => row;

  @override
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData) async =>
      {'_id': 'created-id', '_owner': 'test-owner', ...projectData};

  @override
  Future<Map<String, dynamic>> createJoinRequest(Map<String, dynamic> joinRequestData) async =>
      {'_id': 'req-1', '_owner': 'u1', 'user_id': 'u1', ...joinRequestData};

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(String userId) async => [
        {'_id': 'req-1', '_owner': userId, 'user_id': userId, 'project_id': 'p1', 'status': {'state': 'pending'}}
      ];

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsForProject(String projectId) async => [
        {'_id': 'req-1', '_owner': 'u1', 'user_id': 'u1', 'project_id': projectId, 'status': {'state': 'pending'}}
      ];

  @override
  Future<Map<String, dynamic>> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async =>
      {'_id': requestId, 'status': {'state': status}, 'reviewed_by': reviewedBy};

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async =>
      {'_id': 'prof-1', '_owner': userId, 'name': 'Test User'};

  @override
  Future<Map<String, dynamic>> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  }) async =>
      {'_id': 'member-1', 'project_id': projectId, 'user_id': userId, 'role': role ?? {'name': 'collaborator'}};

  @override
  Future<List<Map<String, dynamic>>> readProjectMembers({String? projectId}) async => [
        {'_id': 'member-1', 'project_id': projectId ?? 'p1', 'user_id': 'u1', 'role': {'name': 'owner'}}
      ];
}




void main() {
  group('ProjectRepository', () {
    test('obtiene y mapea proyectos correctamente desde el datasource', () async {
      final repo = ProjectRepository(InMemoryProjectDataSource());
      final projects = await repo.getProjects();

      expect(projects, isNotEmpty);
      expect(projects.first.id, '1');
      expect(projects.first.title, contains('Kirche'));
      expect(projects.first.jobs, isNotEmpty);
      expect(projects.first.skills, isNotEmpty);
      expect(projects.first.isOpen, isTrue);
    });

    test('mapea jobs y skills cuando vienen como array en la raíz de la columna', () async {
      final source = _SingleProjectDataSource({
        '_id': '42',
        '_owner': 'u1',
        'title': 'Test',
        'imageUrl': '',
        'description': '',
        'jobs': ['Dev', 'Designer'],
        'skills': '["Dart", "Flutter"]', // jsonb serializado como texto
        'status': 'open',
      });
      final repo = ProjectRepository(source);
      final project = await repo.getProjectById('42');

      expect(project!.jobs, ['Dev', 'Designer']);
      expect(project.skills, ['Dart', 'Flutter']);
    });

    test('devuelve lista vacía si la columna no es un array en la raíz', () async {
      final valoresNoSoportados = <Object?>[
        {'values': ['Dev', 'Designer']}, // envoltorio legado, ya no soportado
        {'otherKey': ['Dart']}, // mapa arbitrario
        'Dart, Flutter', // texto plano
        null,
      ];

      for (final jobs in valoresNoSoportados) {
        final repo = ProjectRepository(_SingleProjectDataSource({
          '_id': '43',
          '_owner': 'u1',
          'title': 'Test',
          'imageUrl': '',
          'description': '',
          'jobs': jobs,
          'status': 'open',
        }));

        final project = await repo.getProjectById('43');

        expect(project!.jobs, isEmpty, reason: 'no debería leer: $jobs');
      }
    });

    test('obtiene un proyecto por ID', () async {
      final repo = ProjectRepository(InMemoryProjectDataSource());
      final project = await repo.getProjectById('2');

      expect(project, isNotNull);
      expect(project!.id, '2');
      expect(project.title, contains('AquaNet'));
    });

    test('devuelve null si el ID no existe', () async {
      final repo = ProjectRepository(InMemoryProjectDataSource());
      final project = await repo.getProjectById('9999');

      expect(project, isNull);
    });

    test('traduce RobleApiNetworkException a ProjectFailure comprensible', () async {
      final repo = ProjectRepository(
        _FailingDataSource(const RobleApiNetworkException('Network error')),
      );

      expect(
        () => repo.getProjects(),
        throwsA(
          isA<ProjectFailure>().having(
            (e) => e.message,
            'message',
            contains('Sin conexión'),
          ),
        ),
      );
    });

    test('traduce 404 de RobleApiHttpException a ProjectFailure', () async {
      final repo = ProjectRepository(
        _FailingDataSource(
          const RobleApiHttpException(404, 'Not found'),
        ),
      );

      expect(
        () => repo.getProjectById('1'),
        throwsA(
          isA<ProjectFailure>().having(
            (e) => e.message,
            'message',
            contains('No se encontró'),
          ),
        ),
      );
    });

    test('crea un proyecto con los arrays planos en la raíz de la fila', () async {
      final source = InMemoryProjectDataSource(DummyData());
      final repo = ProjectRepository(source);

      final project = await repo.createProject(
        title: 'Nuevo Proyecto Test',
        description: 'Descripción de prueba',
        jobs: ['Ing. Sistemas'],
        skills: ['Flutter'],
      );

      expect(project.id, isNotEmpty);
      expect(project.title, 'Nuevo Proyecto Test');
      expect(project.jobs, ['Ing. Sistemas']);
      expect(project.skills, ['Flutter']);

      final stored = (await source.readProjects()).last;
      expect(stored['jobs'], ['Ing. Sistemas']);
      expect(stored['skills'], ['Flutter']);
    });

    test('crea una solicitud de colaboración (project_join_request)', () async {
      final source = InMemoryProjectDataSource(DummyData());
      final repo = ProjectRepository(source);

      final request = await repo.createJoinRequest(
        projectId: 'p-100',
        status: {'state': 'pending'},
      );

      expect(request.id, isNotEmpty);
      expect(request.projectId, 'p-100');
      expect(request.statusState, 'pending');
    });

    test('obtiene las solicitudes de un proyecto (getJoinRequestsForProject)', () async {
      final source = InMemoryProjectDataSource(DummyData());
      final repo = ProjectRepository(source);

      await repo.createJoinRequest(
        projectId: 'p-300',
        userId: 'user-a',
        status: {'state': 'pending'},
      );

      final projectRequests = await repo.getJoinRequestsForProject('p-300');
      expect(projectRequests, isNotEmpty);
      expect(projectRequests.first.projectId, 'p-300');
      expect(projectRequests.first.userId, 'user-a');
    });

    test('actualiza el estado de una solicitud (updateJoinRequestStatus)', () async {
      final source = InMemoryProjectDataSource(DummyData());
      final repo = ProjectRepository(source);

      final created = await repo.createJoinRequest(
        projectId: 'p-400',
        userId: 'user-b',
        status: {'state': 'pending'},
      );

      final updated = await repo.updateJoinRequestStatus(
        requestId: created.id,
        status: 'accepted',
        reviewedBy: 'owner-1',
      );

      expect(updated.id, created.id);
      expect(updated.statusState, 'accepted');
      expect(updated.reviewedBy, 'owner-1');
    });
  });
}


