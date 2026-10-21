import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/profile/ui/viewmodels/people_directory.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/applicant.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/person_profile_page.dart';
import 'package:imker/features/projects/ui/viewmodels/collaboration_requests_controller.dart';
import 'package:imker/features/projects/ui/views/applicant_detail_page.dart';
import 'package:imker/features/projects/ui/widgets/inviter_row.dart';
import 'package:imker/core/utils/app_keys.dart';

import '../../../../support/dummy_data.dart';

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

const _project = Project(
  id: 'p1',
  owner: 'owner-1',
  title: 'Proyecto Solaria',
  imageUrl: '',
  description: '',
  jobs: [],
  skills: [],
);

void main() {
  late _Profiles profiles;

  setUp(() {
    Get.reset();
    profiles = _Profiles();
    Get.put<IProfileRepository>(profiles);
  });

  tearDown(Get.reset);

  group('InviterRow', () {
    Future<void> show(WidgetTester tester) async {
      Get.put(PeopleDirectory());
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: InviterRow(inviterId: 'jefe')),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('dice quién te invitó', (tester) async {
      await show(tester);

      expect(find.text('Te invitó Nombre de jefe'), findsOneWidget);
    });

    testWidgets('mientras no se sabe quién es no ofrece abrir nada', (
      tester,
    ) async {
      profiles.failure = const ProfileFailure('Sin conexión.');
      await show(tester);

      expect(find.text('Te invitaron…'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });

  group('ApplicantDetailPage', () {
    late IProjectRepository repo;
    late Applicant applicant;

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      repo = ProjectRepository(InMemoryProjectDataSource(DummyData().projects));
      Get.put<IProjectRepository>(repo);
      Get.put(
        CollaborationRequestsController(
          repository: repo,
          currentUserId: () => 'owner-1',
          isOwner: (_) => true,
        ),
      );
      await repo.createJoinRequest(
        projectId: 'p1',
        userId: 'ana',
        status: 'pending',
      );
      final controller = Get.find<CollaborationRequestsController>();
      await controller.fetchForProject('p1');
      applicant = controller.applicants.single;
      await tester.pumpWidget(
        GetMaterialApp(
          home: ApplicantDetailPage(project: _project, applicant: applicant),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('es la misma ficha: perfil real y la solicitud encima', (
      tester,
    ) async {
      await open(tester);

      expect(find.byType(PersonProfilePage), findsOneWidget);
      expect(find.text('Solicitud de colaboración'), findsOneWidget);
      expect(
        find.textContaining('Quiere colaborar en «Proyecto Solaria»'),
        findsOneWidget,
      );
      expect(find.text('Derecho - Uninorte'), findsOneWidget);
      expect(find.text('Litigante en formación.'), findsOneWidget);
      expect(find.text('Oratoria'), findsOneWidget);
    });

    testWidgets('ya no trae el selector inerte ni datos inventados', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Perfil General'), findsNothing);
      expect(find.textContaining('Rol solicitado'), findsNothing);
      expect(find.textContaining('en común'), findsNothing);
    });

    testWidgets('aceptar registra a la persona como miembro', (tester) async {
      await open(tester);

      await tester.tap(find.byKey(AppKeys.requestAccept));
      await tester.pumpAndSettle();

      expect(await repo.getMemberProjectIds('ana'), ['p1']);
    });

    testWidgets('rechazar no la registra', (tester) async {
      await open(tester);

      await tester.tap(find.byKey(AppKeys.requestReject));
      await tester.pumpAndSettle();

      expect(await repo.getMemberProjectIds('ana'), isEmpty);
    });
  });
}
