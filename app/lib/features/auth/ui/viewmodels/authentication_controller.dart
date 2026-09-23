import 'package:imker/features/auth/domain/models/authentication_user.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'package:imker/core/data/dummy_data.dart';
import '../../../../core/utils/error_message.dart';

import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

class AuthenticationController extends GetxController with UiLoggy {
  final IAuthRepository repoAuthentication;

  final _logged = false.obs;
  final _isAnonymous = false.obs;
  final _loggedUser = Rxn<AuthenticationUser>();
  final _isLoading = false.obs;

  /// Vacío mientras la última operación de auth fue exitosa.
  final RxString error = ''.obs;

  AuthenticationController(this.repoAuthentication);

  bool get isLoading => _isLoading.value;
  bool get isLogged => _logged.value;
  bool get isAnonymous => _isAnonymous.value;
  String get loggedEmail => _loggedUser.value?.email ?? '';
  String get loggedName => _loggedUser.value?.name ?? '';

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    _isLoading.value = true;
    try {
      final restored = await repoAuthentication.restoreSession();
      _logged.value = restored;
      _isAnonymous.value = restored ? repoAuthentication.isAnonymous : false;
      _loggedUser.value = restored ? await repoAuthentication.getLoggedUser() : null;
      if (restored) _refreshUserProjects();
    } catch (exception) {
      loggy.warning('AuthController: restoreSession failed — $exception');
      _logged.value = false;
      _isAnonymous.value = false;
      _loggedUser.value = null;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> login(String email, String password) async {
    loggy.debug('AuthController: login $email');
    error.value = '';
    if (!_validate(email, password)) {
      error.value = 'Correo o contraseña inválidos (mínimo 7 caracteres).';
      return false;
    }
    _isLoading.value = true;
    try {
      final ok = await repoAuthentication.login(
        AuthenticationUser(email: email, name: email, password: password),
      );
      _logged.value = ok;
      _isAnonymous.value = false;
      _loggedUser.value = ok ? await repoAuthentication.getLoggedUser() : null;
      if (ok) _refreshUserProjects();
      if (!ok) error.value = 'No se pudo iniciar sesión. Verifica tus datos.';
      return ok;
    } catch (exception) {
      loggy.error('AuthController: login error — $exception');
      error.value = errorMessage(exception);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }


  /// Acceso rápido para desarrollo y pruebas locales (usado en kDebugMode).
  Future<bool> quickDevLogin() async {
    return login(DummyData.devEmail, DummyData.devPassword);
  }

  Future<bool> signUp(String email, String password, {String name = ''}) async {
    loggy.debug('AuthController: signUp $email');
    error.value = '';
    if (email.isEmpty || !email.contains('@')) {
      error.value = 'Correo inválido.';
      return false;
    }
    _isLoading.value = true;
    try {
      final effectiveName = name.trim().isNotEmpty ? name.trim() : email;
      final created = await repoAuthentication.signUp(
        AuthenticationUser(email: email, name: effectiveName, password: password),
      );
      if (!created) error.value = 'No se pudo crear la cuenta. Intenta de nuevo.';
      return created;
    } catch (exception) {
      loggy.error('AuthController: signUp error — $exception');
      error.value = errorMessage(exception);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> logOut() async {
    loggy.debug('AuthController: logOut');
    error.value = '';
    try {
      await repoAuthentication.logOut();
    } catch (exception) {
      loggy.error('AuthController: logOut error — $exception');
      // Aunque falle el servidor, limpiamos el estado local.
    } finally {
      _logged.value = false;
      _isAnonymous.value = false;
      _loggedUser.value = null;
      _refreshUserProjects();
    }
    return true;
  }

  void _refreshUserProjects() {
    if (Get.isRegistered<UserProjectsController>()) {
      Get.find<UserProjectsController>().fetchCoCreatedProjects();
    }
  }


  // ─── Invitado ─────────────────────────────────────────────────────────────

  /// Abre una sesión anónima. El invitado puede navegar y luego completar cuenta.
  Future<bool> signInAsGuest() async {
    loggy.debug('AuthController: signInAsGuest');
    error.value = '';
    _isLoading.value = true;
    try {
      final ok = await repoAuthentication.signInAnonymously();
      _logged.value = ok;
      _isAnonymous.value = ok;
      _loggedUser.value = ok ? await repoAuthentication.getLoggedUser() : null;
      return ok;
    } catch (exception) {
      loggy.error('AuthController: signInAsGuest error — $exception');
      error.value = errorMessage(exception);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Convierte al invitado en cuenta real. Conserva el mismo _id y sus filas.
  /// La validación de fortaleza de contraseña la hace Roble server-side.
  /// Si el email ya pertenece a otra cuenta, Roble falla y se muestra el error.
  Future<bool> upgradeAccount(String email, String password, String name) async {
    loggy.debug('AuthController: upgradeAccount $email');
    error.value = '';
    if (email.isEmpty || !email.contains('@')) {
      error.value = 'Correo inválido.';
      return false;
    }
    if (password.isEmpty) {
      error.value = 'Ingresa una contraseña.';
      return false;
    }
    _isLoading.value = true;
    try {
      final ok = await repoAuthentication.upgradeAccount(email, password, name);
      if (ok) {
        _isAnonymous.value = false;
        _loggedUser.value = await repoAuthentication.getLoggedUser();
      }
      return ok;
    } catch (exception) {
      loggy.error('AuthController: upgradeAccount error — $exception');
      error.value = errorMessage(exception);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  bool _validate(String email, String password) =>
      email.isNotEmpty && email.contains('@') && password.length >= 7;
}

