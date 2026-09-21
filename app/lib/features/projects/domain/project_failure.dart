/// Fallo tipado de la feature `discover`.
///
/// El repositorio atrapa las excepciones del SDK de Roble ([RobleApiException]
/// y sus subclases) y las traduce a este tipo antes de que escalen a la UI.
/// De esta forma, la capa de presentación nunca ve códigos HTTP, nombres de
/// tablas ni detalles de infraestructura: solo un mensaje en lenguaje natural
/// listo para mostrar al usuario.
class ProjectFailure implements Exception {
  const ProjectFailure(this.message);

  final String message;

  @override
  String toString() => 'ProjectFailure: $message';
}
