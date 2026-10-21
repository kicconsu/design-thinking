import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/widgets/trust_indicators.dart';

Widget _wrap(TrustIndicators child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('muestra los valores y el nombre "Cumplimiento"', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TrustIndicators(
          commitmentScore: 72,
          onTimeScore: 80,
          fulfillmentScore: 65,
          completedProjectsScore: 50,
        ),
      ),
    );

    expect(find.text('72%'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Cumplimiento'), findsOneWidget);
    expect(find.text('Tasa de respuesta'), findsNothing);
  });

  testWidgets('un indicador sin datos sale como «—», no como 0 %', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TrustIndicators(
          commitmentScore: 100,
          onTimeScore: null,
          fulfillmentScore: null,
          completedProjectsScore: 100,
        ),
      ),
    );

    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('un 0 real se muestra como 0 %', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TrustIndicators(
          commitmentScore: 0,
          onTimeScore: 0,
          fulfillmentScore: 0,
          completedProjectsScore: 0,
        ),
      ),
    );

    expect(find.text('0%'), findsNWidgets(4));
    expect(find.text('—'), findsNothing);
  });
}
