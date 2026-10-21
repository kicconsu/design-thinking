import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/features/projects/data/datasources/roble_project_data_source.dart';

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
