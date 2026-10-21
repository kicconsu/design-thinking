import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/profile/ui/viewmodels/people_directory.dart';

class _Profiles implements IProfileRepository {
  final asked = <String>[];
  ProfileFailure? failure;

  @override
  Future<UserProfile> getProfileOf(String userId) async {
    asked.add(userId);
    if (failure != null) throw failure!;
    return UserProfile(
      name: 'Nombre de $userId',
      program: 'Derecho',
      institution: 'Uninorte',
      bio: 'Litigante en formación.',
      skills: const ['Oratoria'],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Profiles profiles;

  setUp(() {
    Get.reset();
    profiles = _Profiles();
    Get.put<IProfileRepository>(profiles);
  });

  tearDown(Get.reset);

  group('PeopleDirectory', () {
    test('lee una vez por persona aunque se pida muchas veces', () async {
      final directory = PeopleDirectory();

      await Future.wait([
        directory.load('ana'),
        directory.load('ana'),
        directory.load('ana'),
      ]);
      await directory.load('ana');

      expect(profiles.asked, ['ana']);
      expect(directory.summaryOf('ana')?.name, 'Nombre de ana');
      expect(directory.summaryOf('ana')?.career, 'Derecho - Uninorte');
    });

    test('si no se pudo leer devuelve null y se puede reintentar', () async {
      final directory = PeopleDirectory();
      profiles.failure = const ProfileFailure('Sin conexión.');

      expect(await directory.load('ana'), isNull);
      expect(directory.summaryOf('ana'), isNull);

      profiles.failure = null;
      expect((await directory.load('ana'))?.name, 'Nombre de ana');
    });

    test('clear olvida todo', () async {
      final directory = PeopleDirectory();
      await directory.load('ana');

      directory.clear();

      expect(directory.summaryOf('ana'), isNull);
    });

    test('una lectura de la sesión anterior no escribe en la nueva', () async {
      final directory = PeopleDirectory();
      final slow = directory.load('ana');

      directory.clear();
      await slow;

      expect(directory.summaryOf('ana'), isNull);
    });

    test('un id vacío no lee nada', () async {
      expect(await PeopleDirectory().load(''), isNull);
      expect(profiles.asked, isEmpty);
    });
  });
}
