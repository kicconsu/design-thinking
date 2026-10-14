import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/utils/career_label.dart';
import 'package:imker/features/profile/data/datasources/i_profile_data_source.dart';
import 'package:imker/features/profile/data/repositories/profile_repository.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:roble/roble.dart';

class _FakeDataSource implements IProfileDataSource {
  _FakeDataSource([this.row]);

  Map<String, dynamic>? row;
  Object? exception;

  void _throwIfFailing() {
    final error = exception;
    if (error != null) throw error;
  }

  @override
  Future<Map<String, dynamic>?> readMyProfile() async {
    _throwIfFailing();
    return row;
  }

  @override
  Future<Map<String, dynamic>?> readProfileOf(String userId) async {
    _throwIfFailing();
    return row;
  }

  @override
  Future<Map<String, dynamic>?> ensureMyProfile({required String name}) async {
    _throwIfFailing();
    return row ??= {'name': name, 'skills': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> updateMyProfile({
    required String program,
    required String institution,
    required String bio,
    required List<String> skills,
  }) async {
    _throwIfFailing();
    return row = {
      ...?row,
      'career': careerToJson(program: program, institution: institution),
      'description': bio,
      'skills': skills,
    };
  }
}

void main() {
  group('ProfileRepository', () {
    test('mapea skills cuando vienen como array en la raíz de la columna', () async {
      final repo = ProfileRepository(
        _FakeDataSource({
          'description': 'Resumen',
          'skills': ['Python', 'SQL'],
        }),
      );

      final profile = await repo.getMyProfile();

      expect(profile.bio, 'Resumen');
      expect(profile.skills, ['Python', 'SQL']);
    });

    test('decodifica skills serializadas como jsonb en texto', () async {
      final repo = ProfileRepository(
        _FakeDataSource({'skills': '["Python", "SQL"]'}),
      );

      final profile = await repo.getMyProfile();

      expect(profile.skills, ['Python', 'SQL']);
    });

    test('devuelve skills vacías si la columna no es un array', () async {
      final repo = ProfileRepository(
        _FakeDataSource({'skills': {'values': ['Python']}}),
      );

      final profile = await repo.getMyProfile();

      expect(profile.skills, isEmpty);
    });

    test('arma academicInfo desde el objeto career', () async {
      final repo = ProfileRepository(
        _FakeDataSource({
          'career': {'program': 'Ing. Sistemas', 'institution': 'U. de la Costa'},
        }),
      );

      final profile = await repo.getMyProfile();

      expect(profile.academicInfo, 'Ing. Sistemas - U. de la Costa');
    });

    test('separa carrera e institución y arma academicInfo', () async {
      final repo = ProfileRepository(
        _FakeDataSource({
          'career': {'program': 'Ing. Sistemas', 'institution': 'Uninorte'},
        }),
      );

      final profile = await repo.getMyProfile();

      expect(profile.program, 'Ing. Sistemas');
      expect(profile.institution, 'Uninorte');
    });

    test('los indicadores de confianza valen 0 y no hay historial', () async {
      final repo = ProfileRepository(_FakeDataSource({'skills': ['Dart']}));

      final profile = await repo.getMyProfile();

      expect(profile.commitmentScore, 0);
      expect(profile.completedProjectsScore, 0);
      expect(profile.hasTrustHistory, isFalse);
    });

    test('isComplete exige carrera y al menos una habilidad', () async {
      Future<bool> complete(Map<String, dynamic> row) async =>
          (await ProfileRepository(_FakeDataSource(row)).getMyProfile())
              .isComplete;

      expect(await complete({}), isFalse);
      expect(await complete({'career': {'program': 'X'}}), isFalse);
      expect(await complete({'skills': ['Dart']}), isFalse);
      expect(
        await complete({'career': {'program': 'X'}, 'skills': ['Dart']}),
        isTrue,
      );
    });

    test('updateMyProfile devuelve el perfil con la carrera nueva', () async {
      final repo = ProfileRepository(_FakeDataSource({}));

      final profile = await repo.updateMyProfile(
        program: 'Derecho',
        institution: 'Uninorte',
        bio: 'Hola',
        skills: ['Oratoria'],
      );

      expect(profile.academicInfo, 'Derecho - Uninorte');
      expect(profile.bio, 'Hola');
      expect(profile.skills, ['Oratoria']);
    });

    test('devuelve un perfil vacío si el usuario todavía no tiene fila', () async {
      final repo = ProfileRepository(_FakeDataSource(null));

      final profile = await repo.getMyProfile();

      expect(profile.bio, isEmpty);
      expect(profile.skills, isEmpty);
      expect(profile.academicInfo, isEmpty);
    });

    test('getProfileOf lee el perfil de otra persona', () async {
      final repo = ProfileRepository(
        _FakeDataSource({
          'description': 'Hola',
          'career': {'program': 'Derecho'},
          'skills': ['Oratoria'],
        }),
      );

      final profile = await repo.getProfileOf('otra-persona');

      expect(profile.program, 'Derecho');
      expect(profile.skills, ['Oratoria']);
    });

    test('getProfileOf sin fila devuelve un perfil vacío', () async {
      final repo = ProfileRepository(_FakeDataSource(null));

      expect((await repo.getProfileOf('otra-persona')).isComplete, isFalse);
    });

    test('traduce RobleApiNetworkException a ProfileFailure comprensible', () async {
      final source = _FakeDataSource()
        ..exception = const RobleApiNetworkException('Network error');
      final repo = ProfileRepository(source);

      expect(
        () => repo.getMyProfile(),
        throwsA(
          isA<ProfileFailure>().having(
            (e) => e.message,
            'message',
            contains('Sin conexión'),
          ),
        ),
      );
    });
  });
}
