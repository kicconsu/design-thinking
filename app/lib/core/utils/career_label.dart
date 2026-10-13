import 'dart:convert';

/// Texto legible de la columna `career` de `profile`.
///
/// `career` no tiene todavía una convención definida por el equipo de
/// backend: puede llegar como texto plano o como un objeto
/// `{"program": ..., "institution": ...}`. Se manejan ambos casos y,
/// si no calza ninguno, se devuelve vacío en vez de fallar.
String formatCareer(Object? value) {
  if (value == null) return '';
  Object? raw = value;
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    try {
      raw = jsonDecode(trimmed);
    } catch (_) {
      return trimmed;
    }
  }
  if (raw is Map) {
    final program = (raw['program'] as String?)?.trim() ?? '';
    final institution = (raw['institution'] as String?)?.trim() ?? '';
    if (program.isEmpty && institution.isEmpty) return '';
    if (program.isEmpty) return institution;
    if (institution.isEmpty) return program;
    return '$program - $institution';
  }
  return '';
}
