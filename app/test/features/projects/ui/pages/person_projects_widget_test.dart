import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/auth/domain/models/authentication_user.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/person_profile_page.dart';
import 'package:imker/features/projects/ui/pages/project_detail_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

/// Perfiles con nombre propio por usuario.
class _Source extends InMemoryProjectDataSource {
  _Source(super.data);

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async => {
    'name': 'Nombre de $userId',
    'career': {'program': 'Ingeniería'},
  };
}

class _Auth implements IAuthRepository {
  _Auth({required this.anonymous});

  final bool anonymous;

  @override
  Future<bool> restoreSession() async => true;

  @override
  Future<AuthenticationUser?> getLoggedUser() async =>
      AuthenticationUser(email: 'yo@x.co', name: 'Yo', password: '', id: 'yo');

  @override
  bool get isAnonymous => anonymous;

  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles implements IProfileRepository {
  @override
  Future<UserProfile> getProfileOf(String userId) async =>
      const UserProfile(program: 'Derecho', skills: ['Oratoria']);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Source source;
  late ProjectRepository repo;

  setUp(() {
    Get.reset();
    source = _Source(DummyData().projects);
    repo = ProjectRepository(source);
    Get.put<IProjectRepository>(repo);
    Get.put<IProfileRepository>(_Profiles());
  });

  tearDown(Get.reset);

  Future<String> createProject(String title) async => (await repo.createProject(
    title: title,
    description: 'd',
    jobs: const [],
    skills: const [],
  )).id;

  group('PersonProfilePage', () {
    Future<void> open(
      WidgetTester tester, {
      ProjectMember? member,
      String? projectId,
    }) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          home: PersonProfilePage(
            userId: 'ana',
            name: 'Ana Pérez',
            member: member,
            projectId: projectId,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra en qué anda: sus proyectos', (tester) async {
      final pid = await createProject('Proyecto de Ana');
      await repo.addProjectMember(projectId: pid, userId: 'ana');

      await open(tester);

      expect(find.text('Proyectos'), findsOneWidget);
      expect(find.text('Proyecto de Ana'), findsOneWidget);
    });

    testWidgets('una persona sin proyectos lo dice', (tester) async {
      await open(tester);

      expect(
        find.text('Todavía no participa en ningún proyecto.'),
        findsOneWidget,
      );
    });

    testWidgets('sin proyecto de contexto no hay tarjeta «En este proyecto»', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('En este proyecto'), findsNothing);
    });

    testWidgets('abierta desde un proyecto, la tarjeta sí sale', (
      tester,
    ) async {
      final pid = await createProject('P');
      await open(
        tester,
        projectId: pid,
        member: const ProjectMember(userId: 'ana', name: 'Ana Pérez'),
      );

      expect(find.text('En este proyecto'), findsOneWidget);
    });

    testWidgets('si no se pueden leer los proyectos, no inventa «ninguno»', (
      tester,
    ) async {
      Get.delete<IProjectRepository>(force: true);
      Get.put<IProjectRepository>(_FailingProjects());

      await open(tester);

      expect(find.text('Proyectos'), findsNothing);
      expect(find.textContaining('ningún proyecto'), findsNothing);
      expect(find.text('Oratoria'), findsOneWidget);
    });
  });

  group('Integrantes en el detalle del proyecto', () {
    Future<void> openDetail(
      WidgetTester tester, {
      bool anonymous = false,
    }) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      Get.put(AuthenticationController(_Auth(anonymous: anonymous)));
      Get.put(UserProjectsController());
      await repo.addProjectMember(
        projectId: DummyData.kircheId,
        userId: 'jefe',
        role: {'name': 'owner'},
      );
      await repo.addProjectMember(projectId: DummyData.kircheId, userId: 'ana');
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Get.to(
                  () => ProjectDetailPage(project: DummyData.kircheProject),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('lista a la gente real, con su papel', (tester) async {
      await openDetail(tester);

      expect(find.text('Integrantes'), findsOneWidget);
      expect(find.text('Nombre de jefe'), findsOneWidget);
      expect(find.text('Nombre de ana'), findsOneWidget);
      expect(find.text('Creador'), findsOneWidget);
    });

    testWidgets('tocar a alguien abre su ficha', (tester) async {
      await openDetail(tester);
      await tester.ensureVisible(find.text('Nombre de ana'));

      await tester.tap(find.text('Nombre de ana'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonProfilePage), findsOneWidget);
      expect(find.text('Oratoria'), findsOneWidget);
    });

    testWidgets('un invitado no abre perfiles: se le pide una cuenta', (
      tester,
    ) async {
      await openDetail(tester, anonymous: true);
      await tester.ensureVisible(find.text('Nombre de ana'));

      await tester.tap(find.text('Nombre de ana'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonProfilePage), findsNothing);
      expect(find.text('Cuenta requerida'), findsOneWidget);

      // Deja que termine el aviso para no dejar temporizadores pendientes.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}

class _FailingProjects implements IProjectRepository {
  @override
  Future<List<Project>> getProjectsOfPerson(String userId) async =>
      throw const ProjectFailure('Sin conexión.');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
