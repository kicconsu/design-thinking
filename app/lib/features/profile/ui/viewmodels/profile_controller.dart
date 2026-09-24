import 'package:get/get.dart';

import 'package:imker/core/utils/error_message.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/profile_failure.dart';
import '../../domain/repositories/i_profile_repository.dart';

class ProfileController extends GetxController {
  ProfileController(this._repository);

  final IProfileRepository _repository;

  final Rxn<UserProfile> _profile = Rxn<UserProfile>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString error = RxnString();

  UserProfile? get profile => _profile.value;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      error.value = null;
      _profile.value = await _repository.getMyProfile();
    } on ProfileFailure catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = errorMessage(e, fallback: 'Ocurrió un error inesperado al cargar tu perfil.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile({required String bio, required List<String> skills}) async {
    try {
      isSaving.value = true;
      error.value = null;
      _profile.value = await _repository.updateMyProfile(bio: bio, skills: skills);
      return true;
    } on ProfileFailure catch (e) {
      error.value = e.message;
      return false;
    } catch (e) {
      error.value = errorMessage(e, fallback: 'No se pudo actualizar tu perfil.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
