import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/ui/widgets/profile_form_fields.dart';

void main() {
  group('ProfileFormController', () {
    test('arranca con los valores del perfil', () {
      final form = ProfileFormController(
        const UserProfile(
          program: 'Medicina',
          institution: 'Uninorte',
          bio: 'Hola',
          skills: ['Dart'],
        ),
      );

      expect(form.programText, 'Medicina');
      expect(form.institutionText, 'Uninorte');
      expect(form.bioText, 'Hola');
      expect(form.skills, ['Dart']);
      expect(form.isEmpty, isFalse);
    });

    test('sin perfil está vacío', () {
      expect(ProfileFormController().isEmpty, isTrue);
    });

    test(
      'addSkill recorta, ignora vacíos y repetidos sin importar mayúsculas',
      () {
        final form = ProfileFormController();

        for (final text in ['  Dart ', '', 'dart', 'SQL']) {
          form.newSkill.text = text;
          form.addSkill();
        }

        expect(form.skills, ['Dart', 'SQL']);
        expect(form.newSkill.text, isEmpty);
      },
    );

    test('removeSkill quita y avisa a quien escucha', () {
      final form = ProfileFormController(
        const UserProfile(skills: ['Dart', 'SQL']),
      );
      var notified = 0;
      form.addListener(() => notified++);

      form.removeSkill('Dart');

      expect(form.skills, ['SQL']);
      expect(notified, 1);
    });
  });
}
