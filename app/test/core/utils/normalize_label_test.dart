import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/utils/normalize_label.dart';

void main() {
  group('normalizeLabel', () {
    test('unifica las variantes de «Ing. Software»', () {
      const variants = [
        'Ing. Software',
        'ing software',
        'Ing.  Software ',
        'Ing. Sóftware',
      ];
      expect(variants.map(normalizeLabel).toSet(), {'ing software'});
    });

    test('quita tildes, diéresis y la eñe', () {
      expect(normalizeLabel('Diseño GRÁFICO'), 'diseno grafico');
      expect(normalizeLabel('Pingüino'), 'pinguino');
    });

    test('convierte . , - / en espacio y colapsa espacios', () {
      expect(normalizeLabel('UI/UX-design, web'), 'ui ux design web');
      expect(normalizeLabel('  a   b\tc  '), 'a b c');
    });

    test('no expande abreviaturas ni une sinónimos', () {
      expect(
        normalizeLabel('Ingeniería de Software'),
        isNot(normalizeLabel('Ing. Software')),
      );
      expect(normalizeLabel('JS'), isNot(normalizeLabel('JavaScript')));
    });

    test('vacío y solo separadores dan vacío', () {
      expect(normalizeLabel(''), '');
      expect(normalizeLabel('  . - / '), '');
    });
  });
}
