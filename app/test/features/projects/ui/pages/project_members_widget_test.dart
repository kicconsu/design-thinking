import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/project_info_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

/// Perfiles distintos por usuario, y uno que falla.
class _Source extends InMemoryProjectDataSource {
  _Source(super.data);

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async {
    if (userId == 'roto') throw StateError('sin permiso');
    if (userId == 'sin-perfil') return null;
    return {
      'name': 'Nombre de $userId',
      'career': {'program': 'Ingeniería', 'institution': 'Uninorte'},
    };
  }
}

void main() {
  late _Source source;
  late ProjectRepository repo;
  const projectId = DummyData.kircheId;

  setUp(() {
    Get.reset();
    source = _Source(DummyData().projects);
    repo = ProjectRepository(source);
    Get.put<IProjectRepository>(repo);
  });

  tearDown(Get.reset);

  Future<void> join(String userId, {String role = 'collaborator'}) =>
      repo.addProjectMember(
        projectId: projectId,
        userId: userId,
        role: {'name': role},
      );

  testWidgets('la pestaña Miembros lista a la gente con su papel', (
    tester,
  ) async {
    Get.put(UserProjectsController());
    await join('jefe', role: 'owner');
    await join('ana');

    await tester.pumpWidget(
      GetMaterialApp(
        home: ProjectInfoPage(
          project: DummyData.kircheProject,
          currentUserId: () => 'ana',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Miembros'));
    await tester.pumpAndSettle();

    expect(find.text('2 miembros'), findsOneWidget);
    expect(find.text('Nombre de jefe'), findsOneWidget);
    expect(find.text('Nombre de ana (Tú)'), findsOneWidget);
    expect(find.text('Creador'), findsOneWidget);
    expect(find.text('Colaborador'), findsOneWidget);
    expect(find.text('Ingeniería - Uninorte'), findsNWidgets(2));
  });
}
