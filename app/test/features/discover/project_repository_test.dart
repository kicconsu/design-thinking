import 'package:flutter_test/flutter_test.dart';
import 'package:f_clean_template/features/discover/data/datasources/i_project_data_source.dart';
import 'package:f_clean_template/features/discover/data/datasources/in_memory_project_data_source.dart';
import 'package:f_clean_template/features/discover/data/repositories/project_repository.dart';
import 'package:f_clean_template/features/discover/domain/project_failure.dart';
import 'package:roble/roble.dart';

class _FailingDataSource implements IProjectDataSource {
  _FailingDataSource(this.exception);
  final Object exception;

  @override
  Future<List<Map<String, dynamic>>> readProjects() async => throw exception;

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async => throw exception;
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
  });
}
