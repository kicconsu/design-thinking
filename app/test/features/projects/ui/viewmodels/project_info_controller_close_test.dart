import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/project_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

void main() {
  late DummyData data;
  late InMemoryProjectDataSource source;
  late ProjectRepository repo;
  late String projectId;

  setUp(() async {
    Get.reset();
    data = DummyData();
    source = InMemoryProjectDataSource(data.projects);
    repo = ProjectRepository(source);
    Get.put<IProjectRepository>(repo);
    final project = await repo.createProject(
      title: 'Proyecto',
      description: 'd',
      jobs: const [],
      skills: const [],
    );
    projectId = project.id;
  });

  tearDown(Get.reset);

  Map<String, dynamic> row() =>
      data.projects.firstWhere((r) => r['_id'] == projectId);

  group('ProjectInfoController.closeProject', () {
    test(
      'cierra, actualiza la vista y las listas; repetir no hace nada',
      () async {
        final list = UserProjectsController();
        Get.put(list);
        final project = await repo.getProjectById(projectId);
        list.coCreatedProjects.add(project!);
        final info = ProjectInfoController(project);

        expect(await info.closeProject(), isNull);

        expect(info.project.value.isOpen, isFalse);
        expect(list.coCreatedProjects.single.isOpen, isFalse);
        expect(info.isClosing.value, isFalse);
        expect(await info.closeProject(), isNull);
      },
    );
  });
}
