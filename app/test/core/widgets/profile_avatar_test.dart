import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/widgets/profile_avatar.dart';

void main() {
  group('ProfileAvatar.initialsOf', () {
    test('toma la inicial de las dos primeras palabras', () {
      expect(ProfileAvatar.initialsOf('Valentina Ríos Pérez'), 'VR');
      expect(ProfileAvatar.initialsOf('  juan '), 'J');
    });

    test('sin nombre muestra un signo de interrogación', () {
      expect(ProfileAvatar.initialsOf('   '), '?');
    });
  });
}
