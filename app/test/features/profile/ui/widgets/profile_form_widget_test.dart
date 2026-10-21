import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/ui/widgets/profile_form_fields.dart';

void main() {
  testWidgets('ProfileFormFields agrega una habilidad con el botón', (
    tester,
  ) async {
    final form = ProfileFormController(const UserProfile(skills: ['Dart']));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ProfileFormFields(form: form)),
        ),
      ),
    );

    expect(find.text('Dart'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Escribe una habilidad'),
      'Kotlin',
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Kotlin'), findsOneWidget);
    expect(form.skills, ['Dart', 'Kotlin']);
  });
}
