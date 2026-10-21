import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `test/` replica las capas de `lib/`: cada carpeta de pruebas tiene su
/// carpeta homóloga y ninguna prueba queda suelta en la raíz de un feature.
/// Los dobles compartidos viven en `test/support/`.
void main() {
  final testDirs = Directory('test')
      .listSync(recursive: true)
      .whereType<Directory>()
      .map((d) => d.path.replaceAll('\\', '/'))
      .where((path) => path != 'test/support')
      .toList();

  test('cada carpeta de test/ tiene su homóloga en lib/', () {
    final orphans = [
      for (final path in testDirs)
        if (!Directory('lib/${path.substring('test/'.length)}').existsSync())
          path,
    ];

    expect(orphans, isEmpty, reason: 'Sin carpeta homóloga en lib/');
  });

  test('ninguna prueba queda suelta en la raíz de test/ ni de un feature', () {
    final loose = [
      for (final file in Directory('test').listSync().whereType<File>())
        file.path,
      for (final feature in Directory(
        'test/features',
      ).listSync().whereType<Directory>())
        for (final file in feature.listSync().whereType<File>()) file.path,
    ];

    expect(loose, isEmpty, reason: 'Muévelas a la capa que prueban');
  });
}
