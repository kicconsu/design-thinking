import 'package:get/get.dart';

import 'package:imker/core/roble/session_user.dart';

import '../../domain/models/project_member.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';

/// Estado de la pestaña Miembros de un proyecto. Una instancia por entrada.
class ProjectMembersController extends GetxController {
  /// [currentUserId] sustituye a la sesión real: solo para pruebas.
  ProjectMembersController(this.projectId, {String Function()? currentUserId})
    : _userIdOverride = currentUserId;

  final String projectId;
  final String Function()? _userIdOverride;

  final RxList<ProjectMember> members = <ProjectMember>[].obs;
  final RxBool isLoading = false.obs;

  /// Mensaje del último intento fallido; null si el último salió bien.
  final RxnString error = RxnString();

  /// Si ya se intentó cargar: distingue "todavía no" de "no hay nadie".
  final RxBool loaded = false.obs;

  String get currentUserId => (_userIdOverride ?? sessionUserId)();

  bool isMe(ProjectMember member) =>
      currentUserId.isNotEmpty && member.userId == currentUserId;

  /// Lee los miembros. Si falla conserva la lista que ya hubiera y deja el
  /// motivo en [error].
  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final fresh = await Get.find<IProjectRepository>().getProjectMembers(
        projectId,
      );
      members.assignAll(fresh);
      error.value = null;
    } on ProjectFailure catch (e) {
      error.value = e.message;
    } finally {
      loaded.value = true;
      isLoading.value = false;
    }
  }
}
