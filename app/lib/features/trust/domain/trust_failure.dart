/// Fallo tipado de la feature `trust`.
///
/// Igual que [ProfileFailure] y [ProjectFailure]: el repositorio atrapa las
/// excepciones del SDK de Roble y las traduce a este tipo antes de que lleguen
/// a la UI.
class TrustFailure implements Exception {
  const TrustFailure(this.message);

  final String message;

  @override
  String toString() => 'TrustFailure: $message';
}
