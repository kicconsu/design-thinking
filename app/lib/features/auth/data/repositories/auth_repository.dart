import '../../domain/models/authentication_user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/i_authentication_source.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository(this.authenticationSource);

  final IAuthenticationSource authenticationSource;

  @override
  Future<bool> login(AuthenticationUser user) =>
      authenticationSource.login(user);

  @override
  Future<bool> restoreSession() => authenticationSource.restoreSession();

  @override
  Future<AuthenticationUser?> getLoggedUser() =>
      authenticationSource.getLoggedUser();

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    // `register` crea la cuenta pero no deja sesión abierta. Se entra a
    // continuación para que quien se registró quede dentro.
    await authenticationSource.signUp(user);
    return authenticationSource.login(user);
  }

  @override
  Future<bool> logOut() => authenticationSource.logOut();

  @override
  Future<bool> signInAnonymously() => authenticationSource.signInAnonymously();

  @override
  Future<bool> upgradeAccount(String email, String password, String name) =>
      authenticationSource.upgradeAccount(email, password, name);

  @override
  bool get isAnonymous => authenticationSource.isAnonymous;

  @override
  Stream<void> get sessionExpired => authenticationSource.sessionExpired;
}
