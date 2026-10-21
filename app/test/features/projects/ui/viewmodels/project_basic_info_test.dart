import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/project_basic_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/project_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

void main() {
  late DummyData data;
  late ProjectRepository repo;
  const id = DummyData.kircheId;

  setUp(() {
    Get.reset();
    data = DummyData();
    repo = ProjectRepository(InMemoryProjectDataSource(data.projects));
    Get.put<IProjectRepository>(repo);
  });

  tearDown(Get.reset);

  Map<String, dynamic> row() => data.projects.firstWhere((r) => r['_id'] == id);

  group('ProjectBasicInfoController', () {
    late ProjectInfoController info;

    setUp(() => info = ProjectInfoController(DummyData.kircheProject));

    test('solo el creador guarda', () async {
      final guest = ProjectBasicInfoController(info, isOwner: () => false);
      guest.title.text = 'Hackeado';

      expect(await guest.save(), contains('creador'));
      expect(row()['title'], isNot('Hackeado'));
    });

    test('guarda lo marcado, actualiza la vista y las listas', () async {
      final list = UserProjectsController();
      Get.put(list);
      list.coCreatedProjects.add(DummyData.kircheProject);
      final c = ProjectBasicInfoController(info, isOwner: () => true);

      c.title.text = '  Kirche 2 ';
      c.description.text = 'Otra descripción';
      // Se desmarca la primera carrera: no debe guardarse.
      c.jobs = [
        for (var i = 0; i < c.jobs.length; i++)
          i == 0 ? c.jobs[i].copyWith(checked: false) : c.jobs[i],
      ];
      final droppedJob = DummyData.kircheProject.jobs.first;

      expect(await c.save(), isNull);

      expect(info.project.value.title, 'Kirche 2');
      expect(info.project.value.jobs, isNot(contains(droppedJob)));
      expect(list.coCreatedProjects.single.title, 'Kirche 2');
      expect(c.title.text, 'Kirche 2');
      expect(c.isSaving.value, isFalse);
    });

    test(
      'un nombre vacío devuelve el mensaje y conserva el borrador',
      () async {
        final c = ProjectBasicInfoController(info, isOwner: () => true);
        c.title.text = '';
        c.description.text = 'Algo';

        expect(await c.save(), contains('nombre'));
        expect(c.description.text, 'Algo');
      },
    );
  });
}
