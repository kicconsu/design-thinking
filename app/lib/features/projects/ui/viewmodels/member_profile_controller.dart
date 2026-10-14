import 'package:get/get.dart';

import 'package:imker/core/utils/error_message.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';

import '../../domain/models/project_member.dart';

/// Estado de la ficha de un miembro: su perfil (solo lectura). Una instancia
/// por ficha abierta.
class MemberProfileController extends GetxController {
  MemberProfileController(this.member);

  final ProjectMember member;

  final Rxn<UserProfile> profile = Rxn<UserProfile>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      profile.value = await Get.find<IProfileRepository>().getProfileOf(
        member.userId,
      );
      error.value = null;
    } on ProfileFailure catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = errorMessage(
        e,
        fallback: 'No se pudo cargar el perfil de ${member.name}.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
