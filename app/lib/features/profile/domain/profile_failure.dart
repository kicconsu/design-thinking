/// Fallo tipado de la feature `profile`.
///
/// Igual que [ProjectFailure] en la feature `projects`: el repositorio
/// atrapa las excepciones del SDK de Roble y las traduce a este tipo antes
/// de que lleguen a la UI.
class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  @override
  String toString() => 'ProfileFailure: $message';
}
