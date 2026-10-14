import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/profile/ui/widgets/profile_view.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';
import 'package:imker/features/projects/ui/pages/member_profile_page.dart';
import 'package:imker/features/projects/ui/widgets/project_members_tab.dart';

class _FakeProfiles implements IProfileRepository {
  ProfileFailure? failure;
  final asked = <String>[];

  @override
  Future<UserProfile> getProfileOf(String userId) async {
    asked.add(userId);
    if (failure != null) throw failure!;
    return const UserProfile(
      program: 'Derecho',
      institution: 'Uninorte',
      bio: 'Litigante en formación.',
      skills: ['Oratoria'],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _ana = ProjectMember(userId: 'ana-id', name: 'Ana Pérez');

void main() {
  late _FakeProfiles profiles;

  setUp(() {
    Get.reset();
    profiles = _FakeProfiles();
    Get.put<IProfileRepository>(profiles);
  });

  tearDown(Get.reset);

  group('ProfileView de otra persona', () {
    testWidgets('sin proyectos conocidos no afirma «ningún proyecto»', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileView(
                name: 'Ana Pérez',
                profile: const UserProfile(skills: ['Oratoria']),
              ),
            ),
          ),
        ),
      );

      expect(find.text('PROYECTOS'), findsNothing);
      expect(find.text('PROYECTO'), findsNothing);
      expect(find.textContaining('ningún proyecto'), findsNothing);
      expect(find.text('HABILIDAD'), findsOneWidget);
    });
  });

  group('MemberProfilePage', () {
    testWidgets('muestra el perfil de esa persona', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: MemberProfilePage(member: _ana)),
      );
      await tester.pumpAndSettle();

      expect(profiles.asked, ['ana-id']);
      expect(find.text('Ana Pérez'), findsWidgets);
      expect(find.text('Derecho - Uninorte'), findsOneWidget);
      expect(find.text('Litigante en formación.'), findsOneWidget);
      expect(find.text('Oratoria'), findsOneWidget);
    });

    testWidgets('si falla, dice por qué y deja reintentar', (tester) async {
      profiles.failure = const ProfileFailure('Sin conexión. Verifica tu red.');
      await tester.pumpWidget(
        const GetMaterialApp(home: MemberProfilePage(member: _ana)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión. Verifica tu red.'), findsOneWidget);

      profiles.failure = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Oratoria'), findsOneWidget);
    });
  });

  group('ProjectMembersTab', () {
    Widget tab({ValueChanged<ProjectMember>? onOpen, bool canManage = false}) =>
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectMembersTab(
                members: const [_ana],
                isLoading: false,
                loaded: true,
                isMe: (_) => false,
                onOpenMember: onOpen,
                canManage: canManage,
              ),
            ),
          ),
        );

    testWidgets('tocar una tarjeta abre a esa persona', (tester) async {
      ProjectMember? opened;
      await tester.pumpWidget(tab(onOpen: (m) => opened = m));

      await tester.tap(find.text('Ana Pérez'));

      expect(opened?.userId, 'ana-id');
    });

    testWidgets('la pista cambia para quien puede quitar gente', (
      tester,
    ) async {
      await tester.pumpWidget(tab(onOpen: (_) {}));
      expect(find.text('Toca a alguien para ver su perfil.'), findsOneWidget);

      await tester.pumpWidget(tab(onOpen: (_) {}, canManage: true));
      expect(
        find.text('Toca a alguien para ver su ficha o quitarlo del proyecto.'),
        findsOneWidget,
      );
    });

    testWidgets('sin acción no hay pista ni flecha', (tester) async {
      await tester.pumpWidget(tab());

      expect(find.textContaining('Toca a alguien'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
