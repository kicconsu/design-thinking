import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/utils/app_keys.dart';
import 'package:imker/features/projects/ui/widgets/confirm_application_dialog.dart';

import '../../../../support/builders.dart';

final _project = aProject(id: 'p1', owner: 'jefe', title: 'Huerta comunitaria');

void main() {
  var confirmed = 0;

  /// Una pantalla con un botón que abre el diálogo, como en la app.
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showConfirmApplicationDialog(
              context: context,
              project: _project,
              onConfirmed: () => confirmed++,
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  setUp(() => confirmed = 0);

  testWidgets('pregunta por el proyecto al que se va a postular', (
    tester,
  ) async {
    await openDialog(tester);

    expect(find.text('¿Postularte al proyecto?'), findsOneWidget);
    expect(find.text('Huerta comunitaria'), findsOneWidget);
  });

  testWidgets('«Cancelar» cierra sin confirmar', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Postularte al proyecto?'), findsNothing);
    expect(confirmed, 0);
  });

  testWidgets('«Confirmar» cierra y confirma una sola vez', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byKey(AppKeys.confirmApplication));
    await tester.pumpAndSettle();

    expect(find.text('¿Postularte al proyecto?'), findsNothing);
    expect(confirmed, 1);
  });
}
