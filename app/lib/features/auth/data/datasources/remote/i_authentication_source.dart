import '../../../domain/models/authentication_user.dart';

abstract class IAuthenticationSource {
  Future<bool> login(AuthenticationUser user);

  Future<bool> restoreSession();

  Future<AuthenticationUser?> getLoggedUser();

  Future<bool> signUp(AuthenticationUser user);

  Future<bool> logOut();

  Future<bool> validate(String email, String validationCode);

  Future<bool> refreshToken();

  Future<bool> forgotPassword(String email);

  Future<bool> resetPassword(
    String email,
    String newPassword,
    String validationCode,
  );

  Future<bool> verifyToken();

  /// Abre una sesión de invitado sin credenciales.
  /// Cada fila que escriba el invitado queda a su nombre (_owner).
  Future<bool> signInAnonymously();

  /// Convierte al invitado en cuenta real conservando el mismo _id y sus filas.
  /// Lanza excepción si el email ya pertenece a otra cuenta (Roble no fusiona).
  Future<bool> upgradeAccount(String email, String password, String name);

  /// Verdadero si la sesión activa es de invitado (rol anonymous).
  bool get isAnonymous;
}

