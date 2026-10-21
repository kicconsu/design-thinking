import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/utils/string_list.dart';

void main() {
  group('decodeStringList', () {
    test('lee un array en la raíz de la columna', () {
      expect(decodeStringList(['Dart', 'Flutter']), ['Dart', 'Flutter']);
    });

    test('convierte los elementos a texto', () {
      expect(decodeStringList([1, 2.5, true]), ['1', '2.5', 'true']);
    });

    test('decodifica un jsonb serializado como texto', () {
      expect(decodeStringList('["Dart", "Flutter"]'), ['Dart', 'Flutter']);
    });

    test('devuelve vacío para el envoltorio legado {"values": [...]}', () {
      expect(decodeStringList({'values': ['Dart']}), isEmpty);
      expect(decodeStringList('{"values": ["Dart"]}'), isEmpty);
    });

    test('devuelve vacío para texto plano, mapas raros y nulos', () {
      expect(decodeStringList('Dart, Flutter'), isEmpty);
      expect(decodeStringList({'otherKey': ['Dart']}), isEmpty);
      expect(decodeStringList(null), isEmpty);
      expect(decodeStringList(''), isEmpty);
      expect(decodeStringList(42), isEmpty);
    });

    test('devuelve vacío para un array vacío', () {
      expect(decodeStringList(<dynamic>[]), isEmpty);
    });
  });
}
