import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/pages/project_info_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/core/utils/app_keys.dart';

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
