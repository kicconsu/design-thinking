import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/ui/pages/discover_page.dart';
import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

import '../../../../support/fake_discover_repository.dart';
import '../../../../support/builders.dart';

void main() {
  late FakeDiscoverRepository repo;
  late DiscoverController controller;

  setUp(() {
    Get.reset();
    Get.put(UserProjectsController());
    repo = FakeDiscoverRepository([
      aProject(id: 'a', jobs: ['Software'], skills: ['Dart']),
      aProject(
        id: 'b',
        jobs: ['Software'],
        skills: ['Python'],
        status: 'closed',
      ),
      aProject(id: 'c', jobs: ['Diseño'], skills: ['Figma']),
    ]);
  });

  tearDown(Get.reset);

  /// El controlador carga al crearse: las pruebas que cambian los datos o el
  /// filtro antes de mostrar la pantalla lo crean ellas mismas con [start].
  void start() => controller = Get.put(DiscoverController(repo, pageSize: 10));

  Future<void> show(
    WidgetTester tester, {
    double textScale = 1,
    Size size = const Size(1080, 2400),
    double pixelRatio = 2.5,
  }) async {
    if (!Get.isRegistered<DiscoverController>()) start();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: DiscoverPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String field, String option) async {
    await tester.tap(find.byKey(ValueKey('$field-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
  }

  testWidgets('la barra muestra «Filtros» sin contador cuando no hay filtros', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Filtros'), findsOneWidget);
    expect(find.textContaining('proyectos'), findsNothing);
  });

  testWidgets('no hay barra mientras carga por primera vez ni con feed vacío', (
    tester,
  ) async {
    repo.projects = [];
    start();
    await show(tester);

    expect(find.text('Filtros'), findsNothing);
    expect(
      find.text('No hay proyectos disponibles por el momento.'),
      findsOneWidget,
    );
  });

  testWidgets('elegir carrera en la hoja y aplicar filtra el feed', (
    tester,
  ) async {
    await show(tester);
    await openSheet(tester);

    await pick(tester, 'career', 'Diseño');

    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(controller.filter.value.career, 'diseno');
    expect(find.text('Filtros (1)'), findsOneWidget);
    expect(find.byTooltip('Quitar filtro Diseño'), findsOneWidget);
    expect(find.text('Proyecto c'), findsOneWidget);
  });

  testWidgets('las habilidades de la hoja siguen a la carrera elegida', (
    tester,
  ) async {
    await show(tester);
    await openSheet(tester);
    await pick(tester, 'career', 'Diseño');

    await tester.tap(find.byKey(const ValueKey('skill-field')));
    await tester.pumpAndSettle();

    expect(find.text('Figma'), findsOneWidget);
    expect(find.text('Python'), findsNothing);
  });

  testWidgets('cerrar la hoja sin aplicar descarta los cambios', (
    tester,
  ) async {
    await show(tester);
    await openSheet(tester);
    await pick(tester, 'career', 'Diseño');

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(controller.filter.value, ProjectFilter.none);
    expect(find.text('Filtros'), findsOneWidget);
  });

  testWidgets('«Limpiar» en la hoja vuelve todo a «Todas»', (tester) async {
    start();
    await controller.applyFilter(const ProjectFilter(career: 'diseno'));
    await show(tester);
    await openSheet(tester);

    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();

    expect(controller.filter.value.career, 'diseno'); // aún no se aplicó
  });

  testWidgets('«Solo abiertos» es un filtro más en el contador y los chips', (
    tester,
  ) async {
    await show(tester);
    await openSheet(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Filtros (1)'), findsOneWidget);
    expect(find.byTooltip('Quitar filtro Solo abiertos'), findsOneWidget);
  });

  testWidgets('la ✕ de un chip quita ese filtro sin abrir la hoja', (
    tester,
  ) async {
    start();
    await controller.applyFilter(
      const ProjectFilter(career: 'software', skill: 'dart'),
    );
    await show(tester);
    expect(find.text('Filtros (2)'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Quitar filtro Dart'));
    await tester.tap(find.byTooltip('Quitar filtro Dart'));
    await tester.pumpAndSettle();

    expect(controller.filter.value, const ProjectFilter(career: 'software'));
    expect(find.text('Filtros (1)'), findsOneWidget);
  });

  testWidgets('sin coincidencias el botón de la hoja queda desactivado', (
    tester,
  ) async {
    repo.projects = [
      aProject(id: 'b', jobs: ['Software'], status: 'closed'),
    ];
    await show(tester);
    await openSheet(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sin resultados'),
    );
    expect(find.text('Sin resultados'), findsOneWidget);
    expect(button.onPressed, isNull);
  });

  testWidgets('con más de 12 opciones el selector trae buscador', (
    tester,
  ) async {
    repo.projects = [
      for (var i = 0; i < 14; i++) aProject(id: 'p$i', jobs: ['Carrera $i']),
    ];
    start();
    await show(tester);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('career-field')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'carrera 13');
    await tester.pumpAndSettle();

    expect(find.text('Carrera 13'), findsOneWidget);
    expect(find.text('Carrera 2'), findsNothing);
  });

  testWidgets('con pocas opciones el selector no trae buscador', (
    tester,
  ) async {
    await show(tester);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('career-field')));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('con texto al 130 % no hay desbordes en la barra ni en la hoja', (
    tester,
  ) async {
    start();
    await controller.applyFilter(
      const ProjectFilter(career: 'software', skill: 'dart', onlyOpen: true),
    );
    await show(tester, textScale: 1.3);
    await openSheet(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('con la barra y tres etiquetas la tarjeta no se desborda', (
    tester,
  ) async {
    repo.projects = [
      aProject(
        id: 'a',
        jobs: ['Software'],
        skills: [for (var i = 0; i < 12; i++) 'Habilidad $i'],
      ),
    ];
    start();
    await controller.applyFilter(
      const ProjectFilter(
        career: 'software',
        skill: 'habilidad 1',
        onlyOpen: true,
      ),
    );

    // Un teléfono pequeño y uno con fuente grande.
    for (final (size, ratio, scale) in [
      (const Size(720, 1280), 2.0, 1.0),
      (const Size(1080, 2000), 3.0, 1.3),
    ]) {
      await show(tester, size: size, pixelRatio: ratio, textScale: scale);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('la hoja deja libre la barra de navegación del teléfono', (
    tester,
  ) async {
    await show(tester);
    // 120 px físicos (48 dp) de barra de gestos/botones abajo.
    tester.view.padding = const FakeViewPadding(bottom: 120);
    tester.view.viewPadding = const FakeViewPadding(bottom: 120);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpAndSettle();

    await openSheet(tester);

    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final button = tester.getBottomLeft(
      find.widgetWithText(FilledButton, 'Aplicar'),
    );
    expect(button.dy, lessThanOrEqualTo(screen - 48));
  });

  testWidgets('los controles tienen al menos 48 dp de alto', (tester) async {
    await show(tester);

    final button = tester.getSize(find.widgetWithText(FilledButton, 'Filtros'));
    expect(button.height, greaterThanOrEqualTo(48));
  });
}
