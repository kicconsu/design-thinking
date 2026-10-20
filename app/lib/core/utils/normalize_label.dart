const _accented = 'áéíóúüñàèìòù';
const _plain = 'aeiouunaeiou';

final _separators = RegExp(r'[.,/\-]');
final _spaces = RegExp(r'\s+');

/// Clave con la que se comparan etiquetas de texto libre (carreras, habilidades).
///
/// Minúsculas, sin tildes, con `. , - /` convertidos en espacio y los espacios
/// colapsados. No expande abreviaturas: «Ing.» y «Ingeniería» siguen siendo
/// distintas. Debe dar lo mismo que la normalización de las consultas guardadas
/// `proyectos_filtrados` y `opciones_filtros_proyectos` (`docs/db/saved_queries.sql`).
String normalizeLabel(String label) {
  final buffer = StringBuffer();
  for (final rune in label.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final i = _accented.indexOf(char);
    buffer.write(i >= 0 ? _plain[i] : char);
  }
  return buffer
      .toString()
      .replaceAll(_separators, ' ')
      .replaceAll(_spaces, ' ')
      .trim();
}
