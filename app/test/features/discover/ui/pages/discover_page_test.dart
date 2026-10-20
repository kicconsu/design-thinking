import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/ui/pages/discover_page.dart';
import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

import '../../../../support/fake_discover_repository.dart';

Project project(String id, {List<String> jobs = const ['Software']}) => Project(
  id: id,
  title: 'Proyecto $id',
  imageUrl: '',
  description: 'Descripción $id',
  jobs: jobs,
  skills: const [],
);

void main() {
  late FakeDiscoverRepository repo;
  late DiscoverController controller;

  setUp(() {
    Get.reset();
    Get.put(UserProjectsController());
    repo = FakeDiscoverRepository([
      for (var i = 0; i < 8; i++)
        project('p$i', jobs: [i.isEven ? 'Software' : 'Diseño']),
    ]);
    controller = Get.put(DiscoverController(repo, pageSize: 4));
  });

  tearDown(Get.reset);

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: DiscoverPage())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeUp(WidgetTester tester) async {
    await tester.fling(find.byType(PageView), const Offset(0, -400), 2000);
    await tester.pumpAndSettle();
  }

  PageController pageController(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView)).controller!;

  testWidgets('al acercarse al final pide la página siguiente', (tester) async {
    await show(tester);
    expect(controller.projects.length, 4);

    await swipeUp(tester);
    await swipeUp(tester);

    expect(controller.projects.length, 8);
  });

  testWidgets('el PageController es el mismo aunque cambie la lista', (
    tester,
  ) async {
    await show(tester);
    final before = pageController(tester);

    await swipeUp(tester);
    await swipeUp(tester);

    expect(pageController(tester), same(before));
    expect(before.page, greaterThan(0));
  });

  testWidgets('cambiar un filtro vuelve a la primera tarjeta', (tester) async {
    await show(tester);
    await swipeUp(tester);
    expect(pageController(tester).page, greaterThan(0));

    await controller.setCareer('diseno');
    await tester.pumpAndSettle();

    expect(pageController(tester).page, 0);
    expect(find.text('Proyecto p1'), findsOneWidget);
  });

  testWidgets('refrescar con el mismo filtro no mueve la posición', (
    tester,
  ) async {
    await show(tester);
    await swipeUp(tester);
    final page = pageController(tester).page;

    await controller.loadProjects();
    await tester.pumpAndSettle();

    expect(pageController(tester).page, page);
  });

  testWidgets('sin coincidencias ofrece limpiar filtros', (tester) async {
    await show(tester);
    // Con filtros válidos casi no se llega a cero resultados (las opciones salen
    // del propio feed); solo si los datos cambian entre las dos peticiones.
    controller.projects.clear();
    controller.filter.value = const ProjectFilter(career: 'software');
    await tester.pumpAndSettle();

    expect(
      find.text('Ningún proyecto coincide con los filtros.'),
      findsOneWidget,
    );
  });

  testWidgets('un aviso del controlador sale como snackbar', (tester) async {
    await show(tester);

    controller.notice.value = 'Sin conexión';
    await tester.pump();

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(controller.notice.value, isNull);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
