import 'dart:convert';

/// Lee una columna `jsonb` que guarda una lista de textos.
///
/// Sólo se acepta la forma canónica: un array en la raíz de la columna.
/// Si el valor llega serializado como texto (Roble devuelve algunas columnas
/// json como [String]), se decodifica con [jsonDecode] y se vuelve a leer.
///
/// Cualquier otra forma —un objeto, texto plano o `null`— produce una lista
/// vacía en vez de fallar: una fila mal guardada no debe tumbar el mapeo.
List<String> decodeStringList(Object? raw) {
  if (raw is List) return raw.map((e) => e.toString()).toList();

  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];
    try {
      return decodeStringList(jsonDecode(trimmed));
    } on FormatException {
      return const [];
    }
  }

  return const [];
}
