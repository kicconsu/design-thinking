import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/features/profile/data/datasources/roble_profile_data_source.dart';

/// Doble de [RobleApiDataBase]: sólo CRUD en memoria y una sesión fingida.
///
/// `RobleClient.currentUserId` sale del token; aquí se sustituye por el
/// identificador que el test reparte, que es lo único que importa para
/// decidir de quién es cada fila.
class _FakeRobleDb extends RobleApiDataBase {
  _FakeRobleDb({
    required this.sessionUserId,
    required this.rows,
    this.profile = const {},
  }) : super(
          config: RobleApiConfig.fromContract(
            baseUrl: 'https://example.test',
            contractId: 'test_ab12cd34ef',
          ),
          storage: RobleMemoryStorage(),
        );

  String? sessionUserId;
  List<Map<String, dynamic>> rows;
  Map<String, dynamic> profile;

  final created = <Map<String, dynamic>>[];
  final updated = <Map<String, dynamic>>[];

  @override
  String? get currentUserId => sessionUserId;

  @override
  Future<List<Map<String, dynamic>>> read(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    expect(tableName, RobleClient.profileTable);
    return rows;
  }

  @override
  Future<Map<String, dynamic>> create(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    created.add(Map<String, dynamic>.from(data));
    final row = <String, dynamic>{'_id': 'nuevo-${created.length}', ...data};
    rows = [...rows, row];
    return row;
  }

  @override
  Future<Map<String, dynamic>> update(
    String tableName,
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    updated.add({'id': id, ...data});
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>> currentUser() async => profile;
}

const _yo = '97d34b72-2bc7-4555-a41f-e7208955e31c';
const _otro = 'cbefab89-887c-4607-8476-e8d8131e7bf3';

final _filaMia = {'_id': 'mia', '_owner': _yo, 'name': 'Dev'};
final _filaAjena = {'_id': 'ajena', '_owner': _otro, 'name': 'Juan'};

void main() {
  RobleProfileDataSource dataSource(_FakeRobleDb db) =>
      RobleProfileDataSource(RobleClient.withDatabase(db));

  group('RobleProfileDataSource.readMyProfile', () {
    test('devuelve la fila propia aunque otras vengan antes', () async {
      final db = _FakeRobleDb(
        sessionUserId: _yo,
        rows: [_filaAjena, _filaMia],
      );

      final row = await dataSource(db).readMyProfile();

      expect(row?['_id'], 'mia');
    });

    test('devuelve null si ninguna fila es suya, nunca la primera', () async {
      final db = _FakeRobleDb(
        sessionUserId: _yo,
        rows: [_filaAjena, _filaAjena],
      );

      expect(
        await dataSource(db).readMyProfile(),
        isNull,
        reason: 'devolver la primera fila sería dar el perfil de otra persona',
      );
    });

    test('devuelve null sin sesión en vez de adivinar', () async {
      final db = _FakeRobleDb(sessionUserId: null, rows: [_filaMia]);

      expect(await dataSource(db).readMyProfile(), isNull);
    });
  });

  group('RobleProfileDataSource.ensureMyProfile', () {
    test('no crea nada si la fila ya existe', () async {
      final db = _FakeRobleDb(sessionUserId: _yo, rows: [_filaMia]);

      final row = await dataSource(db).ensureMyProfile(name: 'Otro Nombre');

      expect(row?['_id'], 'mia');
      expect(db.created, isEmpty);
    });

    test('crea la fila con el nombre dado cuando falta', () async {
      final db = _FakeRobleDb(sessionUserId: _yo, rows: []);

      final row = await dataSource(db).ensureMyProfile(name: 'Dev');

      expect(db.created, hasLength(1));
      expect(db.created.single['name'], 'Dev');
      expect(row?['name'], 'Dev');
    });

    test('sin sesión no garantiza ninguna fila', () async {
      final db = _FakeRobleDb(sessionUserId: null, rows: []);

      expect(await dataSource(db).ensureMyProfile(name: 'Dev'), isNull);
      expect(db.created, isEmpty);
    });
  });

  group('RobleProfileDataSource.updateMyProfile', () {
    test('escribe sobre la fila propia y no sobre la ajena', () async {
      final db = _FakeRobleDb(
        sessionUserId: _yo,
        rows: [_filaAjena, _filaMia],
      );

      final row = await dataSource(db).updateMyProfile(
        bio: 'Una bio',
        skills: ['Dart'],
      );

      expect(db.updated.single['id'], 'mia');
      expect(row['description'], 'Una bio');
      expect(row['skills'], ['Dart']);
    });

    test('si no hay fila, la crea con el nombre del perfil de auth', () async {
      final db = _FakeRobleDb(
        sessionUserId: _yo,
        rows: [],
        profile: {'userId': _yo, 'name': 'Dev'},
      );

      await dataSource(db).updateMyProfile(bio: 'Una bio', skills: const []);

      expect(db.updated, isEmpty);
      expect(db.created, hasLength(1));
      expect(db.created.single['name'], 'Dev');
      expect(db.created.single['description'], 'Una bio');
    });
  });
}
