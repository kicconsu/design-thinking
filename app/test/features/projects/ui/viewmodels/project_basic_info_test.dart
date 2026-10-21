import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:roble/roble.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/datasources/roble_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/project_info_page.dart';
import 'package:imker/features/projects/ui/viewmodels/project_basic_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/project_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/core/utils/app_keys.dart';

/// Solo registra el `update` que recibe.
class _RecordingDb extends RobleApiDataBase {
  _RecordingDb()
    : super(
        config: RobleApiConfig.fromContract(
          baseUrl: 'https://example.test',
          contractId: 'test_ab12cd34ef',
        ),
        storage: RobleMemoryStorage(),
      );

  String? table;
  dynamic id;
  Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>> update(
    String tableName,
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    table = tableName;
    this.id = id;
    this.data = data;
    return {};
  }
}

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

  group('ProjectRepository.updateProject', () {
    test('guarda y devuelve el proyecto leído de vuelta', () async {
      row()['progress'] = 40.0;

      final updated = await repo.updateProject(
        id: id,
        title: '  Nuevo nombre ',
        description: 'Nueva descripción',
        jobs: const ['Ingeniería Civil'],
        skills: const ['Modelación', 'Diseño urbano'],
      );

      expect(updated.title, 'Nuevo nombre');
      expect(updated.description, 'Nueva descripción');
      expect(updated.jobs, ['Ingeniería Civil']);
      expect(updated.skills, ['Modelación', 'Diseño urbano']);
      // Lo que no se edita se conserva.
      expect(updated.progress, 40);
      expect(updated.owner, row()['_owner']);
      expect(row()['title'], 'Nuevo nombre');
    });

    test('las listas se guardan sin vacíos ni repetidos', () async {
      final updated = await repo.updateProject(
        id: id,
        title: 'T',
        description: 'D',
        jobs: const ['Civil', ' civil ', '', '  '],
        skills: const ['Flutter', 'Dart', 'flutter'],
      );

      expect(updated.jobs, ['Civil']);
      expect(updated.skills, ['Flutter', 'Dart']);
    });

    test('sin nombre o sin descripción falla y no escribe', () async {
      final before = row()['title'];

      await expectLater(
        repo.updateProject(
          id: id,
          title: '   ',
          description: 'D',
          jobs: const [],
          skills: const [],
        ),
        throwsA(isA<ProjectFailure>()),
      );
      await expectLater(
        repo.updateProject(
          id: id,
          title: 'T',
          description: ' ',
          jobs: const [],
          skills: const [],
        ),
        throwsA(isA<ProjectFailure>()),
      );
      expect(row()['title'], before);
    });
  });

  group('RobleProjectDataSource.updateProject', () {
    test('jobs y skills viajan como texto JSON; lo demás tal cual', () async {
      final db = _RecordingDb();
      final source = RobleProjectDataSource(RobleClient.withDatabase(db));

      await source.updateProject('p1', {
        'title': 'T',
        'jobs': ['A', 'B'],
        'skills': <String>[],
      });

      expect(db.table, RobleClient.projects);
      expect(db.id, 'p1');
      expect(db.data!['title'], 'T');
      expect(jsonDecode(db.data!['jobs'] as String), ['A', 'B']);
      expect(db.data!['skills'], '[]');
    });

    test('editar solo el título no vacía jobs ni skills', () async {
      final db = _RecordingDb();
      final source = RobleProjectDataSource(RobleClient.withDatabase(db));

      await source.updateProject('p1', {'title': 'Solo título'});

      expect(db.data, {'title': 'Solo título'});
    });
  });

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

  group('pestaña Info. básica', () {
    Future<void> openBasicTab(WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: ProjectInfoPage(project: DummyData.kircheProject)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Info. básica'));
      await tester.pumpAndSettle();
    }

    testWidgets('el creador edita y guarda; los cambios sobreviven al cambiar '
        'de pestaña', (tester) async {
      final list = UserProjectsController();
      Get.put(list);
      list.userCreatedProjectIds.add(id);

      await openBasicTab(tester);
      expect(find.text('Guardar Cambios'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Nombre editado');
      // Cambiar de pestaña y volver no pierde el borrador.
      await tester.tap(find.text('Progreso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Info. básica'));
      await tester.pumpAndSettle();
      expect(find.text('Nombre editado'), findsOneWidget);

      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      expect(row()['title'], 'Nombre editado');
      expect(
        find.text('Los cambios del proyecto se guardaron.'),
        findsOneWidget,
      );

      // El aviso deja un temporizador de 3 s.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('quien no es el creador la ve de solo lectura', (tester) async {
      Get.put(UserProjectsController());

      await openBasicTab(tester);

      expect(find.text('Guardar Cambios'), findsNothing);
      expect(find.byKey(AppKeys.checklistAdd), findsNothing);
      expect(
        find.text(
          'Solo el creador del proyecto puede editar esta información.',
        ),
        findsOneWidget,
      );
    });
  });
}
