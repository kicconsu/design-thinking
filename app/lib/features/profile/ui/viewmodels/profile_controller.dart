import 'package:get/get.dart';

import 'package:imker/core/utils/error_message.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/profile_failure.dart';
import '../../domain/repositories/i_profile_repository.dart';

/// Perfil de la sesión activa. Una sola instancia durante toda la app
/// (`registerProfileData`): auth lo carga al entrar y lo vacía al salir.
class ProfileController extends GetxController {
  ProfileController(this._repository);

  final IProfileRepository _repository;

  final Rxn<UserProfile> _profile = Rxn<UserProfile>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString error = RxnString();

  /// Cambia al vaciar el controller. Una carga o un guardado que empezó con
  /// otra sesión no debe escribir el perfil de esa persona en la que entra.
  int _epoch = 0;

  UserProfile? get profile => _profile.value;

  /// Olvida el perfil de la sesión que se va.
  void clear() {
    _epoch++;
    _profile.value = null;
    error.value = null;
    isLoading.value = false;
    isSaving.value = false;
  }

  Future<void> loadProfile() async {
    final epoch = _epoch;
    try {
      isLoading.value = true;
      error.value = null;
      final loaded = await _repository.getMyProfile();
      if (epoch != _epoch) return;
      _profile.value = loaded;
    } on ProfileFailure catch (e) {
      if (epoch == _epoch) error.value = e.message;
    } catch (e) {
      if (epoch == _epoch) {
        error.value = errorMessage(
          e,
          fallback: 'Ocurrió un error inesperado al cargar tu perfil.',
        );
      }
    } finally {
      if (epoch == _epoch) isLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    required String program,
    required String institution,
    required String bio,
    required List<String> skills,
  }) async {
    final epoch = _epoch;
    try {
      isSaving.value = true;
      error.value = null;
      final saved = await _repository.updateMyProfile(
        program: program,
        institution: institution,
        bio: bio,
        skills: skills,
      );
      if (epoch != _epoch) return false;
      _profile.value = saved;
      return true;
    } on ProfileFailure catch (e) {
      if (epoch == _epoch) error.value = e.message;
      return false;
    } catch (e) {
      if (epoch == _epoch) {
        error.value = errorMessage(e, fallback: 'No se pudo actualizar tu perfil.');
      }
      return false;
    } finally {
      if (epoch == _epoch) isSaving.value = false;
    }
  }
}
