import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imker/features/profile/ui/pages/collaboration_history_page.dart';
import 'package:imker/features/projects/domain/models/project.dart';

import '../../../../support/builders.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<Project> created = const [],
    List<Project> collaborating = const [],
    bool onlyPrevious = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CollaborationHistoryPage(
          created: created,
          collaborating: collaborating,
          onlyPrevious: onlyPrevious,
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
        aProject(id: 'Mio abierto', title: 'Mio abierto'),
        aProject(id: 'Mio cerrado', title: 'Mio cerrado', status: 'closed'),
      ],
      collaborating: [
        aProject(id: 'Ajeno abierto', title: 'Ajeno abierto'),
        aProject(id: 'Ajeno cerrado', title: 'Ajeno cerrado', status: 'closed'),
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
    await pump(
      tester,
      created: [aProject(id: 'Mio', title: 'Mio')],
    );

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
      created: [aProject(id: 'Mio', title: 'Mio', status: 'closed')],
      collaborating: [aProject(id: 'Ajeno', title: 'Ajeno', status: 'closed')],
    );

    expect(find.text('No colabora en ningún proyecto ahora.'), findsOneWidget);
    expect(find.text('No ha creado proyectos abiertos.'), findsOneWidget);
    expect(y(tester, 'Mio'), greaterThan(y(tester, 'Proyectos anteriores')));
    expect(y(tester, 'Ajeno'), greaterThan(y(tester, 'Proyectos anteriores')));
  });

  testWidgets('onlyPrevious deja solo los proyectos anteriores', (
    tester,
  ) async {
    await pump(
      tester,
      collaborating: [
        aProject(id: 'Vivo', title: 'Vivo'),
        aProject(id: 'Viejo', title: 'Viejo', status: 'closed'),
      ],
      onlyPrevious: true,
    );

    expect(find.text('Proyectos anteriores'), findsOneWidget);
    expect(find.text('Viejo'), findsOneWidget);
    expect(find.text('Vivo'), findsNothing);
    expect(find.text('Colaborando ahora'), findsNothing);
    expect(find.text('Proyectos creados'), findsNothing);
  });
}
