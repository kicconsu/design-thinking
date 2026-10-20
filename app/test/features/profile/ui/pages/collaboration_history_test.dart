import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imker/features/profile/ui/pages/collaboration_history_page.dart';
import 'package:imker/features/projects/domain/models/project.dart';

Project _project(String title, {String status = 'open'}) => Project(
  id: title,
  title: title,
  imageUrl: '',
  description: 'd',
  jobs: const [],
  skills: const [],
  status: status,
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<Project> created = const [],
    List<Project> collaborating = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CollaborationHistoryPage(
          created: created,
          collaborating: collaborating,
        ),
      ),
    );
  }

  /// La posición vertical de un texto: sirve para saber en qué sección está.
  double y(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('los cerrados van a «Proyectos anteriores», creados o no', (
    tester,
  ) async {
    await pump(
      tester,
      created: [
        _project('Mio abierto'),
        _project('Mio cerrado', status: 'closed'),
      ],
      collaborating: [
        _project('Ajeno abierto'),
        _project('Ajeno cerrado', status: 'closed'),
      ],
    );

    final collaboratingY = y(tester, 'Colaborando ahora');
    final createdY = y(tester, 'Proyectos creados');
    final previousY = y(tester, 'Proyectos anteriores');
    expect(collaboratingY, lessThan(createdY));
    expect(createdY, lessThan(previousY));

    // Abiertos: en su sección, antes de «anteriores».
    expect(
      y(tester, 'Ajeno abierto'),
      inInclusiveRange(collaboratingY, createdY),
    );
    expect(y(tester, 'Mio abierto'), inInclusiveRange(createdY, previousY));
    // Cerrados: después de «anteriores».
    expect(y(tester, 'Mio cerrado'), greaterThan(previousY));
    expect(y(tester, 'Ajeno cerrado'), greaterThan(previousY));
    // Cada proyecto sale una sola vez.
    for (final t in [
      'Mio abierto',
      'Mio cerrado',
      'Ajeno abierto',
      'Ajeno cerrado',
    ]) {
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('sin cerrados, «anteriores» muestra su texto vacío', (
    tester,
  ) async {
    await pump(tester, created: [_project('Mio')]);

    expect(
      find.text('Aquí aparecerán los proyectos que ya cerraron.'),
      findsOneWidget,
    );
    expect(find.text('Mio'), findsOneWidget);
  });

  testWidgets('si todo está cerrado, las secciones actuales quedan vacías', (
    tester,
  ) async {
    await pump(
      tester,
      created: [_project('Mio', status: 'closed')],
      collaborating: [_project('Ajeno', status: 'closed')],
    );

    expect(find.text('No colabora en ningún proyecto ahora.'), findsOneWidget);
    expect(find.text('No ha creado proyectos abiertos.'), findsOneWidget);
    expect(y(tester, 'Mio'), greaterThan(y(tester, 'Proyectos anteriores')));
    expect(y(tester, 'Ajeno'), greaterThan(y(tester, 'Proyectos anteriores')));
  });
}
