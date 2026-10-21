import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:roble/roble.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/datasources/roble_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
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

  group('RobleProjectDataSource.updateProject', () {
    test('jobs y skills viajan como texto JSON; lo demás tal cual', () async {
      final db = _RecordingDb();
      final source = RobleProjectDataSource(RobleClient.withDatabase(db));

      await source.updateProject('p1', {
        'title': 'T',
        'jobs': ['A', 'B'],
        'skills': <String>[],
      });

      expect(db.table, RobleClient.projects);
      expect(db.id, 'p1');
      expect(db.data!['title'], 'T');
      expect(jsonDecode(db.data!['jobs'] as String), ['A', 'B']);
      expect(db.data!['skills'], '[]');
    });

    test('editar solo el título no vacía jobs ni skills', () async {
      final db = _RecordingDb();
      final source = RobleProjectDataSource(RobleClient.withDatabase(db));

      await source.updateProject('p1', {'title': 'Solo título'});

      expect(db.data, {'title': 'Solo título'});
    });
  });
}
