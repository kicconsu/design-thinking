import 'dart:async';

import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/core/utils/error_message.dart';
import 'package:imker/features/auth/domain/models/authentication_user.dart';
import 'package:imker/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/profile/ui/viewmodels/profile_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/routes/app_routes.dart';

class AuthenticationController extends GetxController with UiLoggy {
  final IAuthRepository repoAuthentication;

  final _logged = false.obs;
  final _isAnonymous = false.obs;
  final _loggedUser = Rxn<AuthenticationUser>();
  final _isLoading = false.obs;

  /// Vacío mientras la última operación de auth fue exitosa.
  final RxString error = ''.obs;

  StreamSubscription<void>? _expiry;

  AuthenticationController(this.repoAuthentication);

  bool get isLoading => _isLoading.value;
  bool get isLogged => _logged.value;
  bool get isAnonymous => _isAnonymous.value;
  String get loggedEmail => _loggedUser.value?.email ?? '';
  String get loggedName => _loggedUser.value?.name ?? '';

  @override
  void onInit() {
    super.onInit();
    // El paquete avisa sólo cuando la sesión se cae sin que nadie la cierre:
    // `logout()` no emite, así que este aviso nunca aparece por cerrar sesión.
    _expiry = repoAuthentication.sessionExpired.listen((_) => _onSessionExpired());
    _restoreSession();
  }

  @override
  void onClose() {
    _expiry?.cancel();
    super.onClose();
  }

  void _onSessionExpired() {
    if (!_logged.value) return;
    loggy.warning('AuthController: sesión caducada');
    _clearSessionState();
    error.value = 'Tu sesión caducó. Vuelve a entrar.';
    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _clearSessionState() {
    _logged.value = false;
    _isAnonymous.value = false;
    _loggedUser.value = null;
    _dropProfileCache();
  }

  /// El perfil cacheado en memoria pertenece a la sesión que se acaba de ir.
  /// Se borra para que la siguiente persona no encuentre el del anterior.
  void _dropProfileCache() {
    if (Get.isRegistered<ProfileController>()) {
      Get.delete<ProfileController>();
    }
  }

  Future<void> _restoreSession() async {
    _isLoading.value = true;
    try {
      final restored = await repoAuthentication.restoreSession();
      _logged.value = restored;
      _isAnonymous.value = restored ? repoAuthentication.isAnonymous : false;
      _loggedUser.value = restored ? await repoAuthentication.getLoggedUser() : null;
      if (restored) {
        await _ensureProfileExists();
        _refreshUserProjects();
      }
    } catch (exception) {
      loggy.warning('AuthController: restoreSession failed — $exception');
      _clearSessionState();
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
      if (ok) {
        await _ensureProfileExists();
        _refreshUserProjects();
      }
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

  /// Acceso rápido para desarrollo: sólo si se pidió `--dart-define=DEV_LOGIN=true`.
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
      // El repositorio crea la cuenta y entra: quien se registra queda
      // dentro, igual que en cualquier app.
      final created = await repoAuthentication.signUp(
        AuthenticationUser(email: email, name: effectiveName, password: password),
      );
      if (created) {
        _logged.value = true;
        _isAnonymous.value = false;
        _loggedUser.value = await repoAuthentication.getLoggedUser();
        await _ensureProfileExists();
        _refreshUserProjects();
      } else {
        error.value = 'No se pudo crear la cuenta. Intenta de nuevo.';
      }
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
      _clearSessionState();
      _refreshUserProjects();
    }
    return true;
  }

  void _refreshUserProjects() {
    if (Get.isRegistered<UserProjectsController>()) {
      final ctrl = Get.find<UserProjectsController>();
      ctrl.fetchCoCreatedProjects();
      ctrl.fetchUserApplications();
    }
  }

  /// Garantiza que la sesión tenga fila en `profile`.
  ///
  /// Los líderes ven el perfil de los postulantes desde esa tabla, así que un
  /// usuario que nunca abrió su pestaña de perfil tiene que tenerla igual.
  /// Un fallo aquí no arruina el login: se reintenta en el siguiente arranque.
  Future<void> _ensureProfileExists() async {
    if (_isAnonymous.value) return;
    if (!Get.isRegistered<IProfileRepository>()) return;
    final name = loggedName.isNotEmpty ? loggedName : loggedEmail;
    if (name.isEmpty) return;
    try {
      await Get.find<IProfileRepository>().ensureMyProfile(name: name);
    } catch (exception) {
      loggy.warning('AuthController: no se pudo garantizar la fila de perfil — $exception');
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
      if (ok) _refreshUserProjects();
      return ok;
    } catch (exception) {
      loggy.error('AuthController: signInAsGuest error — $exception');
      error.value = errorMessage(exception);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Convierte al invitado en cuenta real. Conserva el mismo userId y sus filas.
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
        _logged.value = true;
        _loggedUser.value = await repoAuthentication.getLoggedUser();
        await _ensureProfileExists();
        _refreshUserProjects();
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
