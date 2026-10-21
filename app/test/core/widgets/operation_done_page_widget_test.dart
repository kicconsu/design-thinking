import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/utils/app_keys.dart';
import 'package:imker/core/widgets/operation_done_page.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, OperationDonePage page) =>
      tester.pumpWidget(MaterialApp(home: page));

  testWidgets('muestra título, texto y la barra de la app', (tester) async {
    await pumpPage(
      tester,
      const OperationDonePage(title: '¡Listo!', text: 'Todo salió bien.'),
    );

    expect(find.text('¡Listo!'), findsOneWidget);
    expect(find.text('Todo salió bien.'), findsOneWidget);
    expect(find.text('Imker'), findsOneWidget);
  });

  testWidgets('con showAppBar en falso no pone barra superior', (tester) async {
    await pumpPage(
      tester,
      const OperationDonePage(title: '¡Listo!', showAppBar: false),
    );

    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('el botón llama a onButtonPressed una vez', (tester) async {
    var taps = 0;
    await pumpPage(
      tester,
      OperationDonePage(
        title: '¡Listo!',
        buttonText: 'Volver',
        onButtonPressed: () => taps++,
      ),
    );

    await tester.tap(find.byKey(AppKeys.operationDoneButton));

    expect(find.text('Volver'), findsOneWidget);
    expect(taps, 1);
  });

  testWidgets('con ícono, el botón lo muestra junto al texto', (tester) async {
    await pumpPage(
      tester,
      OperationDonePage(
        buttonText: 'Seguir',
        buttonIcon: Icons.arrow_forward,
        onButtonPressed: () {},
      ),
    );

    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('Seguir'), findsOneWidget);
  });

  testWidgets('sin buttonText no hay botón', (tester) async {
    await pumpPage(tester, const OperationDonePage(title: '¡Listo!'));

    expect(find.byKey(AppKeys.operationDoneButton), findsNothing);
  });

  testWidgets('un actionButton propio reemplaza al botón por defecto', (
    tester,
  ) async {
    await pumpPage(
      tester,
      OperationDonePage(
        buttonText: 'Por defecto',
        actionButton: const Text('Mi acción'),
      ),
    );

    expect(find.text('Mi acción'), findsOneWidget);
    expect(find.text('Por defecto'), findsNothing);
  });
}
