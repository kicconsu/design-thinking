import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/projects/ui/views/create_project.dart';

void main() {
  setUp(Get.reset);

  testWidgets('Crear proyecto es un único formulario, sin pestaña Miembros', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: CreateProjectPage()));

    expect(find.text('Nombre del proyecto'), findsOneWidget);
    expect(find.text('Miembros'), findsNothing);
    expect(find.textContaining('Aquí irá'), findsNothing);
  });
}
