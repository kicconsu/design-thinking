import '../../../domain/models/authentication_user.dart';

/// Lo que se le puede pedir a un proveedor de autenticación.
///
/// Ni tokens ni cabeceras: eso lo resuelve el paquete de Roble por su cuenta.
/// Aquí sólo hay credenciales, sesión y quién está dentro.
abstract class IAuthenticationSource {
  Future<bool> login(AuthenticationUser user);

  /// Restaura la sesión guardada al arrancar.
  ///
  /// `false` significa «la sesión guardada ya no sirve».
  Future<bool> restoreSession();

  Future<AuthenticationUser?> getLoggedUser();

  /// Crea la cuenta. No deja sesión abierta.
  Future<bool> signUp(AuthenticationUser user);

  Future<bool> logOut();

  /// Abre una sesión de invitado sin credenciales.
  /// Si el invitado escribe filas, quedan a su nombre (_owner).
  Future<bool> signInAnonymously();

  /// Convierte al invitado en cuenta real conservando el mismo userId y sus
  /// filas. Lanza excepción si el email ya pertenece a otra cuenta (Roble no
  /// fusiona).
  Future<bool> upgradeAccount(String email, String password, String name);

  /// Verdadero si la sesión activa es de invitado (rol anonymous).
  bool get isAnonymous;

  /// Avisa cuando la sesión se cae de forma imprevista (token que no se pudo
  /// refrescar). `logout()` no emite aquí: cerrar sesión a propósito no es una
  /// caducidad.
  Stream<void> get sessionExpired;
}
