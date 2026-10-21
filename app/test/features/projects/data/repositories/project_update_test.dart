import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:roble/roble.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

/// Solo registra el `update` que recibe.
class _RecordingDb extends RobleApiDataBase {
  _RecordingDb()
    : super(
        config: RobleApiConfig.fromContract(
          baseUrl: 'https://example.test',
          contractId: 'test_ab12cd34ef',
        ),
        storage: RobleMemoryStorage(),
      );

  String? table;
  dynamic id;
  Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>> update(
    String tableName,
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    table = tableName;
    this.id = id;
    this.data = data;
    return {};
  }
}

void main() {
  late DummyData data;
  late ProjectRepository repo;
  const id = DummyData.kircheId;

  setUp(() {
    Get.reset();
    data = DummyData();
    repo = ProjectRepository(InMemoryProjectDataSource(data.projects));
    Get.put<IProjectRepository>(repo);
  });

  tearDown(Get.reset);

  Map<String, dynamic> row() => data.projects.firstWhere((r) => r['_id'] == id);

  group('ProjectRepository.updateProject', () {
    test('guarda y devuelve el proyecto leído de vuelta', () async {
      row()['progress'] = 40.0;

      final updated = await repo.updateProject(
        id: id,
        title: '  Nuevo nombre ',
        description: 'Nueva descripción',
        jobs: const ['Ingeniería Civil'],
        skills: const ['Modelación', 'Diseño urbano'],
      );

      expect(updated.title, 'Nuevo nombre');
      expect(updated.description, 'Nueva descripción');
      expect(updated.jobs, ['Ingeniería Civil']);
      expect(updated.skills, ['Modelación', 'Diseño urbano']);
      // Lo que no se edita se conserva.
      expect(updated.progress, 40);
      expect(updated.owner, row()['_owner']);
      expect(row()['title'], 'Nuevo nombre');
    });

    test('las listas se guardan sin vacíos ni repetidos', () async {
      final updated = await repo.updateProject(
        id: id,
        title: 'T',
        description: 'D',
        jobs: const ['Civil', ' civil ', '', '  '],
        skills: const ['Flutter', 'Dart', 'flutter'],
      );

      expect(updated.jobs, ['Civil']);
      expect(updated.skills, ['Flutter', 'Dart']);
    });

    test('sin nombre o sin descripción falla y no escribe', () async {
      final before = row()['title'];

      await expectLater(
        repo.updateProject(
          id: id,
          title: '   ',
          description: 'D',
          jobs: const [],
          skills: const [],
        ),
        throwsA(isA<ProjectFailure>()),
      );
      await expectLater(
        repo.updateProject(
          id: id,
          title: 'T',
          description: ' ',
          jobs: const [],
          skills: const [],
        ),
        throwsA(isA<ProjectFailure>()),
      );
      expect(row()['title'], before);
    });
  });
}
