import 'dart:convert';

/// Carrera e institución guardadas en la columna `career` de `profile`.
typedef Career = ({String program, String institution});

/// Lee la columna `career` de `profile`.
///
/// `career` no tiene todavía una convención definida por el equipo de
/// backend: puede llegar como texto plano o como un objeto
/// `{"program": ..., "institution": ...}`. Se manejan ambos casos (el texto
/// plano cuenta como carrera) y, si no calza ninguno, se devuelve vacío en
/// vez de fallar.
Career parseCareer(Object? value) {
  const empty = (program: '', institution: '');
  if (value == null) return empty;
  Object? raw = value;
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return empty;
    try {
      raw = jsonDecode(trimmed);
    } catch (_) {
      return (program: trimmed, institution: '');
    }
  }
  if (raw is Map) {
    return (
      program: (raw['program'] as String?)?.trim() ?? '',
      institution: (raw['institution'] as String?)?.trim() ?? '',
    );
  }
  return empty;
}

/// Objeto que se guarda en `career`; vacío (`{}`) si no hay nada, porque la
/// columna es NOT NULL.
Map<String, dynamic> careerToJson({
  required String program,
  required String institution,
}) {
  final p = program.trim();
  final i = institution.trim();
  return {
    if (p.isNotEmpty) 'program': p,
    if (i.isNotEmpty) 'institution': i,
  };
}

/// Texto legible de la columna `career` ("Programa - Institución").
String formatCareer(Object? value) {
  final career = parseCareer(value);
  if (career.program.isEmpty) return career.institution;
  if (career.institution.isEmpty) return career.program;
  return '${career.program} - ${career.institution}';
}
