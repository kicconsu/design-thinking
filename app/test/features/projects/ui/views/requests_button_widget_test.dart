import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/projects/ui/views/requests_button.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required int count,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => RequestsButton(
            count: count,
            onTap: onTap ?? () {},
            cs: Theme.of(context).colorScheme,
          ),
        ),
      ),
    ),
  );

  testWidgets('con una solicitud usa el singular', (tester) async {
    await pumpButton(tester, count: 1);

    expect(find.text('1 solicitud'), findsOneWidget);
  });

  testWidgets('con cero o varias usa el plural', (tester) async {
    await pumpButton(tester, count: 0);
    expect(find.text('0 solicitudes'), findsOneWidget);

    await pumpButton(tester, count: 3);
    expect(find.text('3 solicitudes'), findsOneWidget);
  });

  testWidgets('tocarlo llama a onTap una vez', (tester) async {
    var taps = 0;
    await pumpButton(tester, count: 2, onTap: () => taps++);

    await tester.tap(find.text('2 solicitudes'));

    expect(taps, 1);
  });
}
