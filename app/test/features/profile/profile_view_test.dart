import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/core/widgets/profile_avatar.dart';
import 'package:imker/core/widgets/trust_indicators.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/ui/pages/settings_page.dart';
import 'package:imker/features/profile/ui/widgets/profile_view.dart';
import 'package:imker/features/projects/domain/models/project.dart';

Project _project(String id, String title) => Project(
  id: id,
  title: title,
  imageUrl: '',
  description: '',
  jobs: const [],
  skills: const [],
);

Widget _host(Widget child) => GetMaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

class _FakeAuth implements IAuthRepository {
  bool loggedOut = false;

  @override
  Future<bool> logOut() async => loggedOut = true;

  @override
  Future<bool> restoreSession() async => false;

  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  bool get isAnonymous => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _full = UserProfile(
  program: 'Ingeniería de Sistemas',
  institution: 'Uninorte',
  bio: 'Me gustan los datos.',
  skills: ['Python', 'SQL'],
);

void main() {
  group('ProfileAvatar.initialsOf', () {
    test('toma la inicial de las dos primeras palabras', () {
      expect(ProfileAvatar.initialsOf('Valentina Ríos Pérez'), 'VR');
      expect(ProfileAvatar.initialsOf('  juan '), 'J');
    });

    test('sin nombre muestra un signo de interrogación', () {
      expect(ProfileAvatar.initialsOf('   '), '?');
    });
  });

  group('ProfileView', () {
    testWidgets('presenta los campos del perfil', (tester) async {
      await tester.pumpWidget(
        _host(
          ProfileView(
            name: 'Valentina Ríos',
            profile: _full,
            isOwn: true,
            projects: [_project('1', 'Proyecto Solaria')],
          ),
        ),
      );

      expect(find.text('Valentina Ríos'), findsOneWidget);
      expect(find.text('Ingeniería de Sistemas - Uninorte'), findsOneWidget);
      expect(find.text('1 proyecto · 2 habilidades'), findsOneWidget);
      expect(find.text('Me gustan los datos.'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Proyecto Solaria'), findsOneWidget);
    });

    testWidgets('sin historial no muestra indicadores ni inventa números', (tester) async {
      await tester.pumpWidget(_host(const ProfileView(name: 'Ana', profile: _full, isOwn: true)));

      expect(find.byType(TrustIndicators), findsNothing);
      expect(find.textContaining('Aparecerán cuando colabores'), findsOneWidget);
    });

    testWidgets('con historial muestra los indicadores', (tester) async {
      await tester.pumpWidget(
        _host(
          const ProfileView(
            name: 'Ana',
            profile: UserProfile(commitmentScore: 90, onTimeScore: 80),
            isOwn: true,
          ),
        ),
      );

      expect(find.byType(TrustIndicators), findsOneWidget);
    });

    testWidgets('perfil vacío propio invita a completarlo', (tester) async {
      await tester.pumpWidget(_host(const ProfileView(name: 'Ana', profile: UserProfile(), isOwn: true)));

      expect(find.text('Agrega tu carrera'), findsOneWidget);
      expect(find.text('Aún no has escrito nada sobre ti.'), findsOneWidget);
      expect(find.text('Aún no agregas habilidades.'), findsOneWidget);
    });

    testWidgets('perfil ajeno no ofrece editar ni ajustes', (tester) async {
      await tester.pumpWidget(
        _host(ProfileView(name: 'Ana', profile: _full, onEdit: () {}, onOpenSettings: () {})),
      );

      expect(find.text('Editar perfil'), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets('el perfil propio abre ajustes y edición', (tester) async {
      var settings = 0;
      var edit = 0;
      await tester.pumpWidget(
        _host(
          ProfileView(
            name: 'Ana',
            profile: _full,
            isOwn: true,
            onOpenSettings: () => settings++,
            onEdit: () => edit++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.tap(find.text('Editar perfil'));

      expect(settings, 1);
      expect(edit, 1);
    });

    testWidgets('muestra «Ver todos» solo si hay más de dos proyectos', (tester) async {
      final three = [for (var i = 0; i < 3; i++) _project('$i', 'P$i')];
      await tester.pumpWidget(_host(ProfileView(name: 'Ana', profile: _full, isOwn: true, projects: three)));

      expect(find.text('Ver todos (3)'), findsOneWidget);
      expect(find.text('P2'), findsNothing);
    });
  });

  group('SettingsPage', () {
    tearDown(Get.reset);

    testWidgets('cerrar sesión pide confirmación y no cierra si se cancela', (tester) async {
      final repo = _FakeAuth();
      Get.put(AuthenticationController(repo));
      await tester.pumpWidget(const GetMaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('¿Estás seguro de que deseas cerrar sesión?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.loggedOut, isFalse);
    });
  });
}
