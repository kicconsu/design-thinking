import 'package:get/get.dart';

import 'package:imker/core/roble/session_user.dart';
import 'package:imker/features/projects/domain/project_failure.dart';

import '../../domain/models/project_task.dart';
import '../../domain/models/subtask.dart';
import '../../domain/models/task_comment.dart';
import '../../domain/models/task_status.dart';
import '../../domain/repositories/i_task_repository.dart';
import 'user_name_cache.dart';

/// Estado de la vista "Progreso de tarea": descripción, checklist y
/// comentarios. Una instancia por entrada.
class TaskProgressController extends GetxController {
  /// [currentUserId] sustituye a la sesión real: solo para pruebas.
  TaskProgressController(
    ProjectTask initial, {
    String Function()? currentUserId,
  }) : task = initial.obs,
       checklist = List<Subtask>.of(initial.subtasks).obs,
       _userIdOverride = currentUserId;

  final Rx<ProjectTask> task;
  final String Function()? _userIdOverride;

  /// Borrador del checklist: lo que se ve en pantalla antes de guardar.
  final RxList<Subtask> checklist;

  final RxBool isSaving = false.obs;

  final RxList<TaskComment> comments = <TaskComment>[].obs;
  final RxBool isLoadingComments = false.obs;
  final RxBool commentsLoaded = false.obs;
  final RxBool isSending = false.obs;

  /// Mensaje del último intento fallido de leer los comentarios.
  final RxnString commentsError = RxnString();

  final UserNameCache _names = UserNameCache();

  ITaskRepository get _repository => Get.find<ITaskRepository>();

  String get currentUserId => (_userIdOverride ?? sessionUserId)();

  /// Solo quien reservó la tarea edita su descripción y su checklist. Los
  /// demás miembros la leen y comentan.
  bool get canEdit {
    final assignee = task.value.assigneeId;
    return assignee != null && assignee == currentUserId;
  }

  /// Por qué no se puede editar, para mostrarlo; null si sí se puede.
  String? get readOnlyReason {
    if (canEdit) return null;
    return task.value.status == TaskStatus.todo
        ? 'Reserva la tarea para poder editarla.'
        : 'Solo quien reservó la tarea puede editarla.';
  }

  /// Nombre de quien escribió un comentario.
  String authorOf(TaskComment comment) {
    if (comment.userId == currentUserId) return 'Tú';
    final name = _names.nameOf(comment.userId);
    if (name != null) return name;
    return comment.userId.length > 8
        ? 'Usuario ${comment.userId.substring(0, 8)}'
        : 'Miembro';
  }

  void setChecklist(List<Subtask> value) => checklist.assignAll(value);

  /// Guarda descripción y checklist. Devuelve null si salió bien o el mensaje
  /// de error para mostrar.
  Future<String?> save(String description) async {
    if (!canEdit) return readOnlyReason;
    if (isSaving.value) return null;
    isSaving.value = true;
    try {
      task.value = await _repository.saveTaskProgress(
        task: task.value,
        description: description.trim(),
        subtasks: List<Subtask>.of(checklist),
      );
      return null;
    } on ProjectFailure catch (e) {
      return e.message;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> loadComments() async {
    if (isLoadingComments.value) return;
    isLoadingComments.value = true;
    try {
      final fresh = await _repository.getComments(task.value);
      comments.assignAll(fresh);
      commentsError.value = null;
      await _names.resolve(fresh.map((c) => c.userId));
    } on ProjectFailure catch (e) {
      commentsError.value = e.message;
    } finally {
      commentsLoaded.value = true;
      isLoadingComments.value = false;
    }
  }

  /// Agrega un comentario. Devuelve null si salió bien o el mensaje de error.
  Future<String?> addComment(String body) async {
    final text = body.trim();
    if (text.isEmpty) return 'Escribe un comentario.';
    final userId = currentUserId;
    if (userId.isEmpty) return 'Necesitas una cuenta para comentar.';
    if (isSending.value) return null;
    isSending.value = true;
    try {
      final comment = await _repository.addComment(
        task: task.value,
        userId: userId,
        body: text,
      );
      comments.insert(0, comment);
      return null;
    } on ProjectFailure catch (e) {
      return e.message;
    } finally {
      isSending.value = false;
    }
  }
}
