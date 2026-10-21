import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/ui/pages/trust_indicators_page.dart';

Widget _page(UserProfile profile, {bool isOwn = true}) => MaterialApp(
  home: TrustIndicatorsPage(profile: profile, isOwn: isOwn),
);

void main() {
  testWidgets('explica qué mide cada indicador', (tester) async {
    await tester.pumpWidget(
      _page(
        const UserProfile(
          hasTrustHistory: true,
          commitmentScore: 70,
          onTimeScore: 80,
          fulfillmentScore: 60,
          completedProjectsScore: 50,
        ),
      ),
    );

    expect(find.text('Promedio de los indicadores con datos.'), findsOneWidget);
    expect(
      find.text('De las tareas que tomó, cuántas terminó.'),
      findsOneWidget,
    );
    expect(
      find.text('De las tareas con fecha límite, cuántas entregó a tiempo.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'De los proyectos en que participó, cuántos llegaron al 100 %.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('un indicador sin datos dice «Sin datos aún»', (tester) async {
    await tester.pumpWidget(
      _page(
        const UserProfile(
          hasTrustHistory: true,
          commitmentScore: 50,
          fulfillmentScore: 50,
        ),
      ),
    );

    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('Sin datos aún'), findsNWidgets(2));
  });

  testWidgets('sin historial explica cuándo aparecen los números', (
    tester,
  ) async {
    await tester.pumpWidget(_page(const UserProfile(), isOwn: false));

    expect(find.text('Todavía no hay indicadores'), findsOneWidget);
    expect(
      find.text('Aparecen cuando colabora en un proyecto.'),
      findsOneWidget,
    );
  });
}
