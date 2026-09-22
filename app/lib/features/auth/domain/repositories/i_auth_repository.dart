import '../models/authentication_user.dart';

abstract class IAuthRepository {
  Future<bool> login(AuthenticationUser user);

  Future<bool> restoreSession();

  Future<AuthenticationUser?> getLoggedUser();

  Future<bool> signUp(AuthenticationUser user);

  Future<bool> logOut();

  Future<bool> validate(String email, String validationCode);

  Future<bool> validateToken();

  Future<void> forgotPassword(String email);

  /// Abre una sesión de invitado sin credenciales.
  Future<bool> signInAnonymously();

  /// Convierte al invitado en cuenta real conservando el mismo _id y sus filas.
  /// Lanza excepción si el email ya pertenece a otra cuenta.
  Future<bool> upgradeAccount(String email, String password, String name);

  /// Verdadero si la sesión activa es de invitado.
  bool get isAnonymous;
}

