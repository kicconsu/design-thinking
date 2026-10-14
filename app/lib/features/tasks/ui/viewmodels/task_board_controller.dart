import 'package:get/get.dart';

import 'package:imker/core/roble/session_user.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

import '../../domain/models/project_task.dart';
import '../../domain/models/task_status.dart';
import '../../domain/repositories/i_task_repository.dart';

/// Estado del gabinete de tareas de un proyecto. Una instancia por entrada.
class TaskBoardController extends GetxController {
  /// [currentUserId] sustituye a la sesión real: solo para pruebas.
  TaskBoardController(this.project, {String Function()? currentUserId})
    : _userIdOverride = currentUserId;

  final Project project;
  final String Function()? _userIdOverride;

  final RxList<ProjectTask> tasks = <ProjectTask>[].obs;
  final RxBool isLoading = false.obs;

  /// Tareas con una reserva en vuelo: evita el doble toque.
  final RxSet<String> reserving = <String>{}.obs;

  /// `user_id` -> nombre, para el "Reservada por ..." de cada tarjeta.
  final RxMap<String, String> _names = <String, String>{}.obs;

  ITaskRepository get _repository => Get.find<ITaskRepository>();

  String get currentUserId => (_userIdOverride ?? sessionUserId)();

  @override
  void onReady() {
    super.onReady();
    load();
  }

  List<ProjectTask> tasksOf(TaskStatus status) =>
      tasks.where((t) => t.status == status).toList();

  /// "Tú", el nombre del perfil o nada si la tarea no tiene responsable.
  String? assigneeLabel(ProjectTask task) {
    final id = task.assigneeId;
    if (id == null) return null;
    if (id == currentUserId) return 'Tú';
    return _names[id] ?? 'Otra persona';
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      tasks.assignAll(await _repository.getTasks(project.id));
      await _loadNames();
    } on ProjectFailure catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadNames() async {
    final missing = {
      for (final t in tasks)
        if (t.assigneeId != null &&
            t.assigneeId != currentUserId &&
            !_names.containsKey(t.assigneeId))
          t.assigneeId!,
    };
    if (missing.isEmpty || !Get.isRegistered<IProjectRepository>()) return;
    for (final id in missing) {
      try {
        final profile = await Get.find<IProjectRepository>().getUserProfile(id);
        final name = (profile?['name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty) _names[id] = name;
      } on ProjectFailure {
        // Sin perfil legible queda "Otra persona".
      }
    }
  }

  /// Crea una tarea pendiente. Devuelve null si salió bien o el mensaje de
  /// error para mostrar.
  Future<String?> createTask({
    required String title,
    String description = '',
  }) async {
    try {
      final task = await _repository.createTask(
        projectId: project.id,
        title: title,
        description: description,
      );
      tasks.add(task);
      return null;
    } on ProjectFailure catch (e) {
      return e.message;
    }
  }

  /// Reserva [task] para el usuario activo. Devuelve null si salió bien o el
  /// mensaje de error. Si otra persona se adelantó, recarga el tablero.
  Future<String?> reserveTask(ProjectTask task) async {
    final userId = currentUserId;
    if (userId.isEmpty) return 'Necesitas una cuenta para reservar tareas.';
    if (!reserving.add(task.id)) return null;
    try {
      final reserved = await _repository.reserveTask(
        task: task,
        userId: userId,
      );
      final i = tasks.indexWhere((t) => t.id == task.id);
      if (i != -1) tasks[i] = reserved;
      return null;
    } on ProjectFailure catch (e) {
      load();
      return e.message;
    } finally {
      reserving.remove(task.id);
    }
  }
}
