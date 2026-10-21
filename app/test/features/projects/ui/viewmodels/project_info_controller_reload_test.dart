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

  setUp(() {
    Get.reset();
    data = DummyData();
    Get.put<IProjectRepository>(
      ProjectRepository(InMemoryProjectDataSource(data.projects)),
    );
  });

  tearDown(Get.reset);

  Map<String, dynamic> row(String id) =>
      data.projects.firstWhere((r) => r['_id'] == id);

  group('ProjectInfoController.reload', () {
    test('toma el progress fresco y actualiza las listas', () async {
      final list = UserProjectsController();
      Get.put(list);
      list.coCreatedProjects.add(DummyData.kircheProject);
      final controller = ProjectInfoController(DummyData.kircheProject);

      row(DummyData.kircheId)['progress'] = 50.0;
      await controller.reload();

      expect(controller.project.value.progress, 50);
      expect(list.coCreatedProjects.single.progress, 50);
    });

    test('una fila sin progress (anterior a la columna) cuenta 0', () async {
      row(DummyData.kircheId).remove('progress');
      final controller = ProjectInfoController(DummyData.kircheProject);

      await controller.reload();

      expect(controller.project.value.progress, 0);
    });
  });
}
