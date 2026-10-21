import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/core/roble/roble_config.dart';
import 'package:imker/core/theme/theme.dart';
import 'package:imker/features/auth/data/datasources/remote/i_authentication_source.dart';
import 'package:imker/features/auth/data/repositories/auth_repository.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/discover/data/local_discover_repository.dart';
import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';
import 'package:imker/features/profile/data/datasources/i_profile_data_source.dart';
import 'package:imker/features/profile/data/repositories/profile_repository.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/profile/ui/viewmodels/people_directory.dart';
import 'package:imker/features/profile/ui/viewmodels/profile_controller.dart';
import 'package:imker/features/projects/data/datasources/i_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/invitations_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';
import 'package:imker/features/tasks/data/datasources/i_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';
import 'package:imker/routes/app_pages.dart';
import 'package:imker/routes/app_routes.dart';

import 'fake_authentication_source.dart';
import 'fake_profile_data_source.dart';
import 'fake_project_data_source.dart';
import 'fake_roble_client.dart';
import 'fake_task_data_source.dart';
import 'fake_trust_repository.dart';
import 'integration_seed.dart';
import 'tap_overlay.dart';

/// Todo lo que una prueba de integración puede sembrar y consultar.
///
/// Es el «backend» de la prueba: la app lee y escribe aquí en lugar de en
/// Roble. Después de recorrer un flujo, la prueba pregunta a estos dobles qué
/// quedó guardado.
class IntegrationEnv {
  IntegrationEnv._({
    required this.user,
    required this.db,
    required this.auth,
    required this.profiles,
    required this.projects,
    required this.tasks,
    required this.trust,
  });

  /// Quien entra a la app en esta prueba.
  final TestPerson user;
  final FakeRobleDb db;
  final FakeAuthenticationSource auth;
  final FakeProfileDataSource profiles;
  final FakeProjectDataSource projects;
  final FakeTaskDataSource tasks;
  final FakeTrustRepository trust;
}

/// Deja la app lista para una prueba, sin tocar Roble.
///
/// Reproduce el cableado de `main()` (perfil → auth → proyectos → tareas →
/// confianza) pero registrando dobles de `integration_test/support` en lugar de los
/// datasources reales. `main()` no se usa porque crea el `RobleClient` real
/// y apunta al servidor de Uninorte.
///
/// [user] es quien inicia sesión. Los demás parámetros son las filas con que
/// arranca el «backend».
IntegrationEnv setUpIntegrationEnv({
  required TestPerson user,
  List<Map<String, dynamic>> projects = const [],
  List<Map<String, dynamic>> members = const [],
  List<Map<String, dynamic>> joinRequests = const [],
  List<Map<String, dynamic>> tasks = const [],
  List<Map<String, dynamic>> taskStays = const [],
}) {
  // Con un contrato vacío la app entra en «modo mock» y cambia de camino
  // (usuario `demo-user`, datos de demostración). Estas pruebas necesitan el
  // camino normal, con sesión y filas de cada persona.
  if (RobleConfig.contractId.isEmpty) {
    throw StateError(
      'Las pruebas de integración no deben correr con '
      '--dart-define=ROBLE_CONTRACT_ID vacío.',
    );
  }

  Get.reset();

  final db = FakeRobleDb(userId: user.id);
  final auth = FakeAuthenticationSource(db: db, name: user.name);
  final profiles = FakeProfileDataSource(
    currentUserId: user.id,
    profiles: Seed.profiles,
  );
  final projectSource = FakeProjectDataSource(
    currentUserId: user.id,
    projects: projects,
    members: members,
    joinRequests: joinRequests,
    profiles: Seed.profiles,
  );
  final taskSource = FakeTaskDataSource(
    currentUserId: user.id,
    projects: projectSource,
    tasks: tasks,
    members: taskStays,
  );
  final trust = FakeTrustRepository();

  // La app considera que hay una sesión «real» solo si encuentra un RobleClient.
  // Este lleva una base de datos que no sale a la red.
  Get.put<RobleClient>(fakeRobleClient(db), permanent: true);

  // Perfil.
  Get.put<IProfileDataSource>(profiles, permanent: true);
  Get.put<IProfileRepository>(
    ProfileRepository(Get.find<IProfileDataSource>()),
    permanent: true,
  );
  Get.put(ProfileController(Get.find<IProfileRepository>()), permanent: true);
  Get.put(PeopleDirectory(), permanent: true);

  // Autenticación.
  Get.put<IAuthenticationSource>(auth, permanent: true);
  Get.put<IAuthRepository>(
    AuthRepository(Get.find<IAuthenticationSource>()),
    permanent: true,
  );
  Get.put(
    AuthenticationController(Get.find<IAuthRepository>()),
    permanent: true,
  );

  // Proyectos.
  Get.put<IProjectDataSource>(projectSource);
  Get.put<IProjectRepository>(
    ProjectRepository(Get.find<IProjectDataSource>()),
  );
  Get.put(UserProjectsController(), permanent: true);
  Get.put(CollaborationRequestsController(), permanent: true);
  Get.put(InvitationsController(), permanent: true);

  // Tareas.
  Get.put<ITaskDataSource>(taskSource);
  Get.put<ITaskRepository>(TaskRepository(Get.find<ITaskDataSource>()));

  // Confianza.
  Get.put<ITrustRepository>(trust);

  // Descubrir. La ruta `/home` llama a `registerDiscover()`, que construiría
  // el repositorio de Roble; como ya hay un DiscoverController, no hace nada.
  // El feed sale de los mismos proyectos que el resto de la app.
  Get.put(
    DiscoverController(LocalDiscoverRepository(Get.find<IProjectRepository>())),
    permanent: true,
  );

  final env = IntegrationEnv._(
    user: user,
    db: db,
    auth: auth,
    profiles: profiles,
    projects: projectSource,
    tasks: taskSource,
    trust: trust,
  );
  expectOnlyTestDoubles();
  return env;
}

/// Falla si la app quedó conectada a algo que no sea un doble de prueba.
///
/// Es la garantía de que ninguna prueba habla con Roble: cada puerta de
/// entrada de datos tiene que ser un `Fake...` de `integration_test/support`.
void expectOnlyTestDoubles() {
  expect(Get.find<RobleClient>().db, isA<FakeRobleDb>());
  expect(Get.find<IAuthenticationSource>(), isA<FakeAuthenticationSource>());
  expect(Get.find<IProfileDataSource>(), isA<FakeProfileDataSource>());
  expect(Get.find<IProjectDataSource>(), isA<FakeProjectDataSource>());
  expect(Get.find<ITaskDataSource>(), isA<FakeTaskDataSource>());
  expect(Get.find<ITrustRepository>(), isA<FakeTrustRepository>());
}

/// La pantalla de arranque de la app, como en `main.dart` (`MyApp`), con dos
/// diferencias: usa el tema de colores de Imker con las fuentes por defecto
/// (`MyApp` descarga Inter y DM Serif Display de Google Fonts, y una prueba no
/// debe depender de internet) y no pasa por `main()`.
/// Espera a que se vayan los avisos de pantalla (`Get.snackbar`). Salen en la
/// parte baja y tapan lo que haya debajo: un toque sobre un botón cubierto cae
/// en el aviso y no en el botón. Si uno no se va, sigue sin fallar.
Future<void> settleSnackbars(WidgetTester tester) async {
  try {
    await pumpUntilGone(
      tester,
      find.byType(GetSnackBar),
      timeout: const Duration(seconds: 10),
    );
  } catch (_) {}
}

/// Arranca una prueba desde cero: desmonta la app de la prueba anterior
/// (aunque haya fallado a la mitad), vacía GetX y recién entonces arma el
/// entorno de esta. Así nada de la app vieja se cierra encima del entorno
/// nuevo.
Future<IntegrationEnv> freshEnv(
  WidgetTester tester,
  IntegrationEnv Function() build,
) async {
  // La app anterior sigue montada: que terminen sus avisos antes de cerrarla.
  await settleSnackbars(tester);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
  Get.reset();
  return build();
}

Widget createHomeScreen() {
  final theme = MaterialTheme(ThemeData(useMaterial3: true).textTheme);
  return GetMaterialApp(
    title: 'Imker',
    theme: theme.light(),
    debugShowCheckedModeBanner: false,
    builder: (context, child) => TapOverlay.wrap(child),
    initialRoute: AppRoutes.splash,
    getPages: AppPages.routes,
  );
}

// ─── Esperas ────────────────────────────────────────────────────────────────

/// Avanza la app [duration] en pasos de 100 ms.
///
/// Se usa en lugar de `pumpAndSettle` cuando hay una animación que no termina
/// (el indicador de carga gira para siempre y `pumpAndSettle` nunca vería la
/// pantalla «quieta»).
Future<void> pumpFor(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 500),
]) async {
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (elapsed < duration) {
    await _pump(tester, step);
    elapsed += step;
  }
}

/// Avanza un cuadro. Si la app lanzó una excepción (un desborde de pantalla,
/// un error de un controlador...), falla diciendo cuál: el reporte final de
/// `flutter drive` la esconde cuando hay más de una.
Future<void> _pump(WidgetTester tester, [Duration? duration]) async {
  await tester.pump(duration);
  final exception = tester.takeException();
  if (exception != null) {
    throw TestFailure(
      'La app lanzó una excepción:\n$exception\n'
      'Textos en pantalla: ${_visibleTexts()}',
    );
  }
}

/// Los textos que se ven ahora mismo, para que un fallo diga qué había en
/// pantalla en lugar de solo qué faltaba.
List<String> _visibleTexts() {
  final texts = <String>{};
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final value = widget.data ?? widget.textSpan?.toPlainText();
    if (value != null && value.trim().isNotEmpty) texts.add(value.trim());
  }
  return texts.take(40).toList();
}

/// Avanza la app hasta que [finder] encuentre algo; falla si no pasa en
/// [timeout].
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (finder.evaluate().isEmpty) {
    if (elapsed >= timeout) {
      throw TestFailure(
        'Pasaron ${timeout.inSeconds} s y no apareció: $finder\n'
        'Textos en pantalla: ${_visibleTexts()}',
      );
    }
    await _pump(tester, step);
    elapsed += step;
  }
  // Un cuadro más para que termine de dibujarse lo que acaba de aparecer.
  await _pump(tester, step);
}

/// Avanza la app hasta que [finder] ya no encuentre nada.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (finder.evaluate().isNotEmpty) {
    if (elapsed >= timeout) {
      throw TestFailure(
        'Pasaron ${timeout.inSeconds} s y sigue ahí: $finder\n'
        'Textos en pantalla: ${_visibleTexts()}',
      );
    }
    await _pump(tester, step);
    elapsed += step;
  }
}

/// Avanza la app hasta que se cumpla [condition]; falla si no pasa en
/// [timeout]. Se usa para esperar un cambio en los dobles (que algo quedó
/// guardado) sin depender de avisos de pantalla que desaparecen solos.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition,
  String description, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (!condition()) {
    if (elapsed >= timeout) {
      throw TestFailure(
        'Pasaron ${timeout.inSeconds} s y no ocurrió: $description\n'
        'Textos en pantalla: ${_visibleTexts()}',
      );
    }
    await _pump(tester, step);
    elapsed += step;
  }
  await _pump(tester, step);
}

/// Corre el cuerpo de una prueba y, si la app lanzó errores, los junta en un
/// solo fallo con su texto y su pila. Sin esto, `flutter drive` solo dice
/// «Multiple exceptions (N)» cuando hay más de uno y esconde cuáles son.
///
/// Al terminar espera a que se vayan los avisos de pantalla (`Get.snackbar`):
/// su cola es estática y un aviso a medias en una prueba trabaría los de la
/// siguiente.
Future<void> runFlow(WidgetTester tester, Future<void> Function() body) async {
  final original = FlutterError.onError;
  final errors = <String>[];
  FlutterError.onError = (details) {
    final stack =
        details.stack?.toString().split('\n').take(10).join('\n') ?? '';
    errors.add('${details.exceptionAsString()}\n$stack');
  };
  try {
    await body();
    await settleSnackbars(tester);
  } catch (error) {
    if (errors.isEmpty) rethrow;
    throw TestFailure(
      '$error\n\nErrores de la app durante la prueba (${errors.length}):\n'
      '${errors.join('\n---\n')}',
    );
  } finally {
    FlutterError.onError = original;
  }
  if (errors.isNotEmpty) {
    throw TestFailure(
      'La app lanzó ${errors.length} error(es) durante la prueba:\n'
      '${errors.join('\n---\n')}',
    );
  }
}

// ─── Gestos ─────────────────────────────────────────────────────────────────

/// Desplaza la pantalla visible hasta que [finder] exista.
///
/// Las listas solo construyen lo que cabe en pantalla: en una ventana pequeña
/// un botón al final de la página ni siquiera existe todavía.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  final scrollable = find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first;
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: scrollable,
    maxScrolls: 60,
  );
}

/// Toca el elemento que encuentra [finder], después de hacerlo visible.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  await settleSnackbars(tester);
  await scrollTo(tester, finder);
  await tester.ensureVisible(finder);
  await _pump(tester, const Duration(milliseconds: 200));
  await tester.tap(finder);
  await _pump(tester);
  await _pace(tester);
}

/// Pausa entre pasos para poder seguir la prueba a simple vista en un
/// teléfono: `--dart-define=STEP_MS=600`. Sin él no espera (CI y local).
const _stepMs = int.fromEnvironment('STEP_MS');

Future<void> _pace(WidgetTester tester) async {
  if (_stepMs > 0) await tester.pump(const Duration(milliseconds: _stepMs));
}

/// Atajo de [tapOn] para un texto exacto.
Future<void> tapText(WidgetTester tester, String text) =>
    tapOn(tester, find.text(text));

/// Vuelve a la pantalla anterior con el botón «atrás» de la barra superior.
Future<void> goBack(WidgetTester tester) async {
  // Las páginas de abajo quedan fuera de pantalla, así que solo cuenta la
  // flecha de la página visible.
  await tester.tap(find.byType(BackButton).first);
  await pumpFor(tester);
  await _pace(tester);
}

// ─── Pasos que comparten varios flujos ──────────────────────────────────────

/// Inicia sesión con la cuenta de prueba desde la pantalla de login y espera a
/// llegar al inicio (la barra inferior con «DESCUBRIR»).
Future<void> logIn(WidgetTester tester, IntegrationEnv env) async {
  await pumpUntilFound(tester, find.text('Inicia sesión para continuar'));

  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), env.auth.email);
  await tester.enterText(fields.at(1), env.auth.password);
  await _pump(tester);

  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await _pump(tester);

  await pumpUntilFound(tester, find.text('DESCUBRIR'));
}

/// En el inicio, abre la pestaña «Proyectos» y espera a que cargue «Mis
/// proyectos» con [count] proyectos.
Future<void> openMyProjects(WidgetTester tester, {int count = 1}) async {
  await tapText(tester, 'PROYECTOS');
  await pumpUntilFound(tester, find.text('Mis proyectos ($count)'));
}

/// Desde «Mis proyectos», abre el proyecto [title].
Future<void> openProjectInfo(WidgetTester tester, String title) async {
  final tile = find.descendant(
    of: find.byType(ProjectTile),
    matching: find.text(title),
  );
  await pumpUntilFound(tester, tile);
  await tapOn(tester, tile);
  await pumpUntilFound(tester, find.text('Información de Proyecto'));
}

/// Desde la información del proyecto, abre el gabinete de tareas.
Future<void> openTaskBoard(WidgetTester tester) async {
  await tapText(tester, 'Ver Tareas');
  await pumpUntilFound(tester, find.text('Gabinete de tareas'));
}
