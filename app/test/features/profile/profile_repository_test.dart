import 'package:flutter_test/flutter_test.dart';
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
  Future<Map<String, dynamic>?> ensureMyProfile({required String name}) async {
    _throwIfFailing();
    return row ??= {'name': name, 'skills': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> updateMyProfile({
    required String bio,
    required List<String> skills,
  }) async {
    _throwIfFailing();
    return row = {...?row, 'description': bio, 'skills': skills};
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

    test('devuelve un perfil vacío si el usuario todavía no tiene fila', () async {
      final repo = ProfileRepository(_FakeDataSource(null));

      final profile = await repo.getMyProfile();

      expect(profile.bio, isEmpty);
      expect(profile.skills, isEmpty);
      expect(profile.academicInfo, isEmpty);
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
