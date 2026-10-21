import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../support/dummy_data.dart';
import 'package:imker/features/discover/ui/widgets/project_card.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

void main() {
  late UserProjectsController projects;

  setUp(() {
    Get.reset();
    projects = Get.put(UserProjectsController());
  });

  tearDown(Get.reset);

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: ProjectCard(project: DummyData.kircheProject),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('en un proyecto propio la esquina muestra una estrella, no el '
      'corazón ni una etiqueta junto a «Leer más»', (tester) async {
    projects.userCreatedProjectIds.add(DummyData.kircheId);

    await show(tester);

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.text('Tu proyecto'), findsNothing);
  });

  testWidgets('tocar la estrella explica que es tuyo', (tester) async {
    projects.userCreatedProjectIds.add(DummyData.kircheId);
    await show(tester);

    await tester.tap(find.byTooltip('Es tu proyecto'));
    await tester.pump();

    expect(find.text('Este proyecto es tuyo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('en un proyecto ajeno sigue el corazón de guardar', (
    tester,
  ) async {
    await show(tester);

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });
}
