import '../models/authentication_user.dart';

abstract class IAuthRepository {
  Future<bool> login(AuthenticationUser user);

  /// Restaura la sesión guardada. `false` sólo si ya no sirve; sin conexión
  /// la excepción de red se propaga.
  Future<bool> restoreSession();

  Future<AuthenticationUser?> getLoggedUser();

  /// Crea la cuenta y deja la sesión abierta.
  Future<bool> signUp(AuthenticationUser user);

  Future<bool> logOut();

  /// Abre una sesión de invitado sin credenciales.
  Future<bool> signInAnonymously();

  /// Convierte al invitado en cuenta real conservando el mismo userId y sus
  /// filas. Lanza excepción si el email ya pertenece a otra cuenta.
  Future<bool> upgradeAccount(String email, String password, String name);

  /// Verdadero si la sesión activa es de invitado.
  bool get isAnonymous;

  /// Avisa cuando la sesión se cae sin que nadie la cierre.
  Stream<void> get sessionExpired;
}
