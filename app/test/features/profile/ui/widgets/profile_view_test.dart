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
      expect(find.text('PROYECTO'), findsOneWidget);
      expect(find.text('Me gustan los datos.'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Proyecto Solaria'), findsOneWidget);
    });

    testWidgets('sin historial no muestra indicadores ni inventa números', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const ProfileView(name: 'Ana', profile: _full, isOwn: true)),
      );

      expect(find.byType(TrustIndicators), findsNothing);
      expect(
        find.textContaining('Aparecerán cuando colabores'),
        findsOneWidget,
      );
    });

    testWidgets('con historial muestra los indicadores', (tester) async {
      await tester.pumpWidget(
        _host(
          const ProfileView(
            name: 'Ana',
            profile: UserProfile(hasTrustHistory: true, commitmentScore: 90, onTimeScore: 80),
            isOwn: true,
          ),
        ),
      );

      expect(find.byType(TrustIndicators), findsOneWidget);
    });

    testWidgets('perfil vacío propio invita a completarlo', (tester) async {
      await tester.pumpWidget(
        _host(
          const ProfileView(name: 'Ana', profile: UserProfile(), isOwn: true),
        ),
      );

      expect(find.text('Agrega tu carrera'), findsOneWidget);
      expect(find.text('Aún no has escrito nada sobre ti.'), findsOneWidget);
      expect(find.text('Aún no agregas habilidades.'), findsOneWidget);
    });

    testWidgets('perfil ajeno no ofrece ajustes', (tester) async {
      await tester.pumpWidget(
        _host(ProfileView(name: 'Ana', profile: _full, onOpenSettings: () {})),
      );

      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets('invita a completar solo si el perfil propio está incompleto', (
      tester,
    ) async {
      var taps = 0;
      Widget view(UserProfile profile, {bool isOwn = true}) => _host(
        ProfileView(
          name: 'Ana',
          profile: profile,
          isOwn: isOwn,
          onComplete: () => taps++,
        ),
      );

      await tester.pumpWidget(view(const UserProfile()));
      expect(find.text('Completa tu perfil'), findsOneWidget);
      await tester.tap(find.text('Completa tu perfil'));
      expect(taps, 1);

      await tester.pumpWidget(view(_full));
      expect(find.text('Completa tu perfil'), findsNothing);

      await tester.pumpWidget(view(const UserProfile(), isOwn: false));
      expect(find.text('Completa tu perfil'), findsNothing);
    });

    testWidgets('el perfil propio abre ajustes', (tester) async {
      var settings = 0;
      await tester.pumpWidget(
        _host(
          ProfileView(
            name: 'Ana',
            profile: _full,
            isOwn: true,
            onOpenSettings: () => settings++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));

      expect(settings, 1);
    });

    testWidgets('muestra dos proyectos y el total en el historial', (
      tester,
    ) async {
      final three = [for (var i = 0; i < 3; i++) _project('$i', 'P$i')];
      await tester.pumpWidget(
        _host(
          ProfileView(
            name: 'Ana',
            profile: _full,
            isOwn: true,
            projects: three,
            onOpenHistory: () {},
          ),
        ),
      );

      expect(find.text('Historial de colaboración (3)'), findsOneWidget);
      expect(find.text('P2'), findsNothing);
    });
  });

  group('SettingsPage', () {
    tearDown(Get.reset);

    testWidgets('cerrar sesión pide confirmación y no cierra si se cancela', (
      tester,
    ) async {
      final repo = _FakeAuth();
      Get.put(AuthenticationController(repo));
      await tester.pumpWidget(const GetMaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(
        find.text('¿Estás seguro de que deseas cerrar sesión?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.loggedOut, isFalse);
    });
  });
}
