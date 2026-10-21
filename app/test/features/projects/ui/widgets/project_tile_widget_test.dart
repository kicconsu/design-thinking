import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';

import '../../../../support/builders.dart';

void main() {
  group('ProjectTile', () {
    Widget tile(int memberCount) => MaterialApp(
      home: Scaffold(
        body: ProjectTile(
          project: aProject(
            id: 'p',
            owner: 'o',
            title: 'Proyecto',
            memberCount: memberCount,
          ),
          onTap: () {},
        ),
      ),
    );

    testWidgets('dice "1 miembro" en singular', (tester) async {
      await tester.pumpWidget(tile(1));

      expect(find.text('1 miembro'), findsOneWidget);
    });

    testWidgets('dice "N miembros" en plural', (tester) async {
      await tester.pumpWidget(tile(4));

      expect(find.text('4 miembros'), findsOneWidget);
    });

    testWidgets('no muestra textos de relleno', (tester) async {
      await tester.pumpWidget(tile(1));

      expect(find.textContaining('Creador del proyecto'), findsNothing);
      expect(find.textContaining('Tú ('), findsNothing);
    });
  });
}
