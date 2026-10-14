import 'package:get/get.dart';

import 'package:imker/core/roble/session_user.dart';
import 'package:imker/core/utils/error_message.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';

import '../../domain/models/project_member.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import 'member_exit.dart';

/// Estado de la ficha de un miembro: su perfil (solo lectura), lo que ha hecho
/// en este proyecto y, para el creador, la acción de quitarlo. Una instancia
/// por ficha abierta.
class MemberProfileController extends GetxController {
  /// [viewerIsCreator]: quien mira es el creador del proyecto.
  /// [currentUserId] sustituye a la sesión real: solo para pruebas.
  MemberProfileController({
    required this.member,
    required this.projectId,
    this.viewerIsCreator = false,
    String Function()? currentUserId,
  }) : _userIdOverride = currentUserId;

  final ProjectMember member;
  final String projectId;
  final bool viewerIsCreator;
  final String Function()? _userIdOverride;

  final Rxn<UserProfile> profile = Rxn<UserProfile>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  /// Tareas de esta persona en el proyecto; null si no se pudieron leer.
  final RxnInt tasksDone = RxnInt();
  final RxnInt tasksDoing = RxnInt();

  final RxBool isRemoving = false.obs;

  String get currentUserId => (_userIdOverride ?? sessionUserId)();

  bool get isMe => currentUserId.isNotEmpty && member.userId == currentUserId;

  /// El creador puede quitar a un colaborador; a sí mismo y a otro creador no.
  bool get canRemove => viewerIsCreator && !isMe && !member.isOwner;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await Future.wait([_loadProfile(), _loadTasks()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadProfile() async {
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
    }
  }

  /// Sin tareas legibles la ficha simplemente no muestra esa parte.
  Future<void> _loadTasks() async {
    if (!Get.isRegistered<ITaskRepository>()) return;
    try {
      final tasks = await Get.find<ITaskRepository>().getTasks(projectId);
      final mine = tasks.where((t) => t.assigneeId == member.userId);
      tasksDone.value = mine.where((t) => t.isDone).length;
      tasksDoing.value = mine.where((t) => !t.isDone).length;
    } on ProjectFailure {
      tasksDone.value = null;
      tasksDoing.value = null;
    }
  }

  /// El creador quita a esta persona. Devuelve null si salió bien o el
  /// mensaje de error. Ya fuera, libera sus tareas sin terminar.
  Future<String?> remove() async {
    if (!canRemove) return 'No puedes quitar a esta persona.';
    if (isRemoving.value) return null;
    isRemoving.value = true;
    try {
      await Get.find<IProjectRepository>().removeMember(
        projectId: projectId,
        memberUserId: member.userId,
        requestedBy: currentUserId,
      );
      await releaseTasksOf(projectId, member.userId);
      return null;
    } on ProjectFailure catch (e) {
      return e.message;
    } finally {
      isRemoving.value = false;
    }
  }
}
