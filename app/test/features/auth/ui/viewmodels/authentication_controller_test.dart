import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

import '../../../../support/fake_auth_repository.dart';

/// Solo registra `ensureMyProfile`; lo demás no se usa aquí.
class _Profiles implements IProfileRepository {
  final ensured = <String>[];
  bool failing = false;

  @override
  Future<void> ensureMyProfile({required String name}) async {
    if (failing) throw StateError('sin red');
    ensured.add(name);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _project = Project(
  id: 'p1',
  owner: 'ana',
  title: 'Proyecto',
  imageUrl: '',
  description: '',
  jobs: [],
  skills: [],
);

void main() {
  late FakeAuthRepository repo;
  late _Profiles profiles;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    repo = FakeAuthRepository();
    profiles = _Profiles();
    Get.put<IProfileRepository>(profiles);
  });

  tearDown(Get.reset);

  /// Crea el controlador y deja que termine de restaurar la sesión.
  Future<AuthenticationController> start() async {
    final controller = Get.put(AuthenticationController(repo));
    await pumpEventQueue();
    return controller;
  }

  group('al arrancar', () {
    test('con sesión guardada entra y carga a la persona', () async {
      repo.restoreResult = true;

      final controller = await start();

      expect(controller.isLogged, isTrue);
      expect(controller.isAnonymous, isFalse);
      expect(controller.loggedUserId, 'user-1');
      expect(controller.loggedEmail, 'ana@uninorte.edu.co');
      expect(controller.isLoading, isFalse);
    });

    test('con sesión guardada garantiza su fila de perfil', () async {
      repo.restoreResult = true;

      await start();

      expect(profiles.ensured, ['Ana']);
    });

    test('sin sesión guardada queda fuera', () async {
      final controller = await start();

      expect(controller.isLogged, isFalse);
      expect(controller.loggedUserId, isEmpty);
      expect(profiles.ensured, isEmpty);
    });

    test('si restaurar falla (sin red) queda fuera y sin cargar', () async {
      repo.restoreError = StateError('sin red');

      final controller = await start();

      expect(controller.isLogged, isFalse);
      expect(controller.isLoading, isFalse);
    });
  });

  group('login', () {
    test('con datos válidos entra', () async {
      final controller = await start();

      final ok = await controller.login('ana@uninorte.edu.co', 'secreta1');

      expect(ok, isTrue);
      expect(controller.isLogged, isTrue);
      expect(controller.error.value, isEmpty);
      expect(repo.lastLogin!.email, 'ana@uninorte.edu.co');
      expect(repo.lastLogin!.password, 'secreta1');
    });

    test('rechaza datos inválidos sin llamar al servidor', () async {
      final controller = await start();

      for (final (email, password) in [
        ('', 'secreta1'),
        ('sin-arroba', 'secreta1'),
        ('ana@uninorte.edu.co', '123456'),
      ]) {
        expect(await controller.login(email, password), isFalse);
        expect(controller.error.value, contains('inválidos'));
      }
      expect(repo.calls.where((c) => c == 'login'), isEmpty);
    });

    test('si el servidor dice que no, lo explica y no entra', () async {
      repo.loginResult = false;
      final controller = await start();

      final ok = await controller.login('ana@uninorte.edu.co', 'secreta1');

      expect(ok, isFalse);
      expect(controller.isLogged, isFalse);
      expect(controller.error.value, contains('No se pudo iniciar sesión'));
      expect(controller.isLoading, isFalse);
    });

    test('si el servidor lanza una excepción, la traduce', () async {
      repo.loginError = Exception('too many requests');
      final controller = await start();

      final ok = await controller.login('ana@uninorte.edu.co', 'secreta1');

      expect(ok, isFalse);
      expect(controller.error.value, contains('Demasiados intentos'));
      expect(controller.isLoading, isFalse);
    });

    test('garantiza la fila de perfil al entrar', () async {
      final controller = await start();

      await controller.login('ana@uninorte.edu.co', 'secreta1');

      expect(profiles.ensured, ['Ana']);
    });

    test('que falle crear el perfil no impide entrar', () async {
      profiles.failing = true;
      final controller = await start();

      final ok = await controller.login('ana@uninorte.edu.co', 'secreta1');

      expect(ok, isTrue);
      expect(controller.isLogged, isTrue);
    });

    test('un intento nuevo borra el error anterior', () async {
      repo.loginResult = false;
      final controller = await start();
      await controller.login('ana@uninorte.edu.co', 'secreta1');
      expect(controller.error.value, isNotEmpty);

      repo.loginResult = true;
      await controller.login('ana@uninorte.edu.co', 'secreta1');

      expect(controller.error.value, isEmpty);
    });
  });

  group('acceso rápido de desarrollo', () {
    test('sin DEV_EMAIL y DEV_PASSWORD avisa y no llama al servidor', () async {
      final controller = await start();

      final ok = await controller.quickDevLogin();

      expect(ok, isFalse);
      expect(controller.error.value, contains('DEV_EMAIL'));
      expect(repo.calls, isNot(contains('login')));
    });
  });

  group('signUp', () {
    test('crea la cuenta y deja la sesión abierta', () async {
      final controller = await start();

      final ok = await controller.signUp(
        'ana@uninorte.edu.co',
        'secreta1',
        name: ' Ana Pérez ',
      );

      expect(ok, isTrue);
      expect(controller.isLogged, isTrue);
      expect(repo.lastSignUp!.name, 'Ana Pérez');
    });

    test('sin nombre usa el correo como nombre', () async {
      final controller = await start();

      await controller.signUp('ana@uninorte.edu.co', 'secreta1');

      expect(repo.lastSignUp!.name, 'ana@uninorte.edu.co');
    });

    test('rechaza un correo inválido sin llamar al servidor', () async {
      final controller = await start();

      expect(await controller.signUp('sin-arroba', 'secreta1'), isFalse);

      expect(controller.error.value, 'Correo inválido.');
      expect(repo.calls, isNot(contains('signUp')));
    });

    test('si no se pudo crear, lo dice', () async {
      repo.signUpResult = false;
      final controller = await start();

      final ok = await controller.signUp('ana@uninorte.edu.co', 'secreta1');

      expect(ok, isFalse);
      expect(controller.isLogged, isFalse);
      expect(controller.error.value, contains('No se pudo crear la cuenta'));
    });

    test('si el servidor lanza una excepción, la traduce', () async {
      repo.signUpError = Exception('ya tiene cuenta');
      final controller = await start();

      final ok = await controller.signUp('ana@uninorte.edu.co', 'secreta1');

      expect(ok, isFalse);
      expect(controller.error.value, isNotEmpty);
      expect(controller.isLoading, isFalse);
    });
  });

  group('invitado', () {
    test('entra como invitado, sin fila de perfil', () async {
      final controller = await start();

      final ok = await controller.signInAsGuest();

      expect(ok, isTrue);
      expect(controller.isLogged, isTrue);
      expect(controller.isAnonymous, isTrue);
      expect(profiles.ensured, isEmpty);
    });

    test('si falla, queda fuera y con el error', () async {
      repo.guestError = Exception('sin red');
      final controller = await start();

      final ok = await controller.signInAsGuest();

      expect(ok, isFalse);
      expect(controller.isLogged, isFalse);
      expect(controller.error.value, isNotEmpty);
    });

    test('completar cuenta lo convierte en una persona real', () async {
      final controller = await start();
      await controller.signInAsGuest();

      final ok = await controller.upgradeAccount(
        'ana@uninorte.edu.co',
        'secreta1',
        'Ana',
      );

      expect(ok, isTrue);
      expect(controller.isAnonymous, isFalse);
      expect(controller.isLogged, isTrue);
      expect(profiles.ensured, ['Ana']);
    });

    test('completar cuenta valida correo y contraseña', () async {
      final controller = await start();

      expect(
        await controller.upgradeAccount('sin-arroba', 'x', 'Ana'),
        isFalse,
      );
      expect(controller.error.value, 'Correo inválido.');

      expect(
        await controller.upgradeAccount('ana@uninorte.edu.co', '', 'Ana'),
        isFalse,
      );
      expect(controller.error.value, 'Ingresa una contraseña.');
      expect(repo.calls, isNot(contains('upgradeAccount')));
    });

    test('si el correo ya es de otra cuenta, sigue como invitado', () async {
      repo.upgradeError = Exception('ya tiene cuenta');
      final controller = await start();
      await controller.signInAsGuest();

      final ok = await controller.upgradeAccount(
        'ana@uninorte.edu.co',
        'secreta1',
        'Ana',
      );

      expect(ok, isFalse);
      expect(controller.isAnonymous, isTrue);
      expect(controller.error.value, isNotEmpty);
    });
  });

  group('cerrar sesión', () {
    test('deja a la persona fuera', () async {
      final controller = await start();
      await controller.login('ana@uninorte.edu.co', 'secreta1');

      final ok = await controller.logOut();

      expect(ok, isTrue);
      expect(controller.isLogged, isFalse);
      expect(controller.loggedUserId, isEmpty);
    });

    test('aunque el servidor falle, el estado local se limpia', () async {
      repo.logOutError = Exception('sin red');
      final controller = await start();
      await controller.login('ana@uninorte.edu.co', 'secreta1');

      await controller.logOut();

      expect(controller.isLogged, isFalse);
    });

    test('vacía las listas de proyectos de quien se va', () async {
      final projects = Get.put(
        UserProjectsController(currentUserId: () => 'ana'),
      );
      projects.coCreatedProjects.add(_project);
      final controller = await start();
      await controller.login('ana@uninorte.edu.co', 'secreta1');

      await controller.logOut();

      expect(projects.coCreatedProjects, isEmpty);
    });
  });

  group('sesión caducada', () {
    test('si la sesión se cae, queda fuera y avisa', () async {
      final controller = await start();
      await controller.login('ana@uninorte.edu.co', 'secreta1');

      repo.expireSession();
      await pumpEventQueue();

      expect(controller.isLogged, isFalse);
      expect(controller.error.value, contains('caducó'));
    });

    test('si nadie había entrado, el aviso no hace nada', () async {
      final controller = await start();

      repo.expireSession();
      await pumpEventQueue();

      expect(controller.error.value, isEmpty);
    });
  });
}
