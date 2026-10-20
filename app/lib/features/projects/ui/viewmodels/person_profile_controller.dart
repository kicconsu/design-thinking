import 'package:get/get.dart';

import 'package:imker/core/roble/session_user.dart';
import 'package:imker/core/utils/error_message.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:imker/features/trust/domain/models/trust_metrics.dart';
import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

import '../../domain/models/project.dart';
import '../../domain/models/project_member.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import 'member_exit.dart';

/// Estado de la ficha de una persona: su perfil (solo lectura) y en qué anda
/// (sus proyectos). Si se abre desde un proyecto y es miembro de él ([member]
/// y [projectId]), añade lo que ha hecho ahí y, para el creador, la acción de
/// quitarla. Con [showTrust] (la ficha de una solicitud) añade además sus
/// indicadores de confianza y el historial de los proyectos en los que
/// participó. Una instancia por ficha abierta.
class PersonProfileController extends GetxController {
  /// [viewerIsCreator]: quien mira es el creador del proyecto.
  /// [currentUserId] sustituye a la sesión real: solo para pruebas.
  PersonProfileController({
    required this.userId,
    required this.name,
    this.projectId,
    this.member,
    this.viewerIsCreator = false,
    this.showTrust = false,
    String Function()? currentUserId,
  }) : _userIdOverride = currentUserId;

  final String userId;
  final String name;

  /// Proyecto desde el que se abrió la ficha, si fue desde uno.
  final String? projectId;

  /// La persona como miembro de [projectId]; null si no lo es o se abrió fuera
  /// de un proyecto (feed, solicitudes, invitaciones).
  final ProjectMember? member;
  final bool viewerIsCreator;

  /// Cargar y mostrar sus indicadores de confianza y su historial. Solo lo
  /// pide quien está decidiendo sobre una solicitud.
  final bool showTrust;
  final String Function()? _userIdOverride;

  /// El perfil tal como llegó de la base, antes de añadirle los indicadores.
  UserProfile? _fetched;

  final Rxn<UserProfile> profile = Rxn<UserProfile>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  /// En qué anda: sus proyectos creados y activos; null si no se pudieron leer
  /// (entonces no se muestra la sección en vez de decir «ninguno»).
  final Rxn<List<Project>> projects = Rxn<List<Project>>();

  /// Sus indicadores de confianza; null si no se pidieron ([showTrust]) o no se
  /// pudieron calcular (entonces la ficha no los afirma).
  final Rxn<TrustMetrics> trust = Rxn<TrustMetrics>();

  /// Todos los proyectos en los que participó alguna vez, menos aquel desde el
  /// que se abrió la ficha ([projectId]). De aquí sale su historial. Null si no
  /// se pidieron o no se pudieron leer.
  final Rxn<List<Project>> participated = Rxn<List<Project>>();

  /// Tareas de esta persona en el proyecto; null si no se pudieron leer.
  final RxnInt tasksDone = RxnInt();
  final RxnInt tasksDoing = RxnInt();

  final RxBool isRemoving = false.obs;

  String get currentUserId => (_userIdOverride ?? sessionUserId)();

  bool get isMe => currentUserId.isNotEmpty && userId == currentUserId;

  /// El creador puede quitar a un colaborador; a sí mismo y a otro creador no.
  bool get canRemove =>
      viewerIsCreator &&
      projectId != null &&
      member != null &&
      !isMe &&
      !member!.isOwner;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await Future.wait([
        _loadProfile(),
        _loadProjects(),
        _loadTasks(),
        _loadTrust(),
        _loadParticipated(),
      ]);
      _publishProfile();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadProfile() async {
    try {
      _fetched = await Get.find<IProfileRepository>().getProfileOf(userId);
      // Sin indicadores que esperar, el perfil sale en cuanto llega.
      if (!showTrust) _publishProfile();
      error.value = null;
    } on ProfileFailure catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = errorMessage(
        e,
        fallback: 'No se pudo cargar el perfil de $name.',
      );
    }
  }

  /// Muestra el perfil. Con [showTrust] espera a tener también los
  /// indicadores: así no se ve un instante «aparecerán cuando colabore» antes
  /// de que lleguen.
  void _publishProfile() {
    final fetched = _fetched;
    if (fetched == null) return;
    final metrics = trust.value;
    profile.value = metrics == null
        ? fetched
        : fetched.copyWith(
            hasTrustHistory: metrics.hasHistory,
            commitmentScore: metrics.commitment,
            onTimeScore: metrics.onTime,
            fulfillmentScore: metrics.fulfillment,
            completedProjectsScore: metrics.completedProjects,
          );
  }

  /// Sin indicadores calculables la ficha cae al texto de «sin historial».
  Future<void> _loadTrust() async {
    if (!showTrust || !Get.isRegistered<ITrustRepository>()) return;
    try {
      trust.value = await Get.find<ITrustRepository>().getTrustMetricsOf(
        userId,
      );
    } on TrustFailure {
      trust.value = null;
    }
  }

  /// Sin proyectos legibles la ficha no muestra el historial.
  Future<void> _loadParticipated() async {
    if (!showTrust || !Get.isRegistered<IProjectRepository>()) return;
    try {
      final all = await Get.find<IProjectRepository>()
          .getProjectsParticipatedBy(userId);
      participated.value = [
        for (final p in all)
          if (p.id != projectId) p,
      ];
    } on ProjectFailure {
      participated.value = null;
    }
  }

  /// Sin proyectos legibles la ficha no muestra esa sección.
  Future<void> _loadProjects() async {
    if (!Get.isRegistered<IProjectRepository>()) return;
    try {
      projects.value = await Get.find<IProjectRepository>().getProjectsOfPerson(
        userId,
      );
    } on ProjectFailure {
      projects.value = null;
    }
  }

  /// Sin tareas legibles la ficha simplemente no muestra esa parte.
  Future<void> _loadTasks() async {
    final pid = projectId;
    if (pid == null || member == null) return;
    if (!Get.isRegistered<ITaskRepository>()) return;
    try {
      final tasks = await Get.find<ITaskRepository>().getTasks(pid);
      final mine = tasks.where((t) => t.assigneeId == userId);
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
    final pid = projectId;
    if (!canRemove || pid == null) return 'No puedes quitar a esta persona.';
    if (isRemoving.value) return null;
    isRemoving.value = true;
    try {
      await Get.find<IProjectRepository>().removeMember(
        projectId: pid,
        memberUserId: userId,
        requestedBy: currentUserId,
      );
      await releaseTasksOf(pid, userId);
      return null;
    } on ProjectFailure catch (e) {
      return e.message;
    } finally {
      isRemoving.value = false;
    }
  }
}
