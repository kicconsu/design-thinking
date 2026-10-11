import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_task.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';

/// Panel visible dentro del contenedor de gestión de un proyecto.
enum ManagementPanel { info, cabinet, task }

/// Estado de la vista de gestión de un proyecto propio: información, gabinete
/// de tareas y progreso de cada tarea.
///
/// Las tareas viven en memoria mientras dure la sesión: todavía no existe una
/// tabla de tareas en Roble donde persistirlas.
class ProjectManagementController extends GetxController {
  final Rxn<Project> selectedProject = Rxn<Project>();
  final Rx<ManagementPanel> panel = ManagementPanel.info.obs;
  final RxnString selectedTaskId = RxnString();
  final RxList<ProjectTask> tasks = <ProjectTask>[].obs;
  final RxBool isSavingProject = false.obs;

  final Set<String> _seededProjects = {};

  // ─── Navegación ───────────────────────────────────────────────────────────

  void open(Project project) {
    _seedExampleTask(project.id);
    panel.value = ManagementPanel.info;
    selectedTaskId.value = null;
    selectedProject.value = project;
  }

  void close() => selectedProject.value = null;

  void showInfo() => panel.value = ManagementPanel.info;

  void showCabinet() {
    panel.value = ManagementPanel.cabinet;
  }

  void openTask(String taskId) {
    selectedTaskId.value = taskId;
    panel.value = ManagementPanel.task;
  }

  // ─── Consultas ────────────────────────────────────────────────────────────

  List<ProjectTask> tasksOf(String projectId, TaskStatus status) =>
      tasks.where((t) => t.projectId == projectId && t.status == status).toList();

  ProjectTask? taskById(String? id) => tasks.firstWhereOrNull((t) => t.id == id);

  List<ProjectTask> _allOf(String projectId) =>
      tasks.where((t) => t.projectId == projectId).toList();

  /// Porcentaje de finalización del proyecto: promedio del avance de sus tareas.
  int completionPercent(String projectId) {
    final all = _allOf(projectId);
    if (all.isEmpty) return 0;
    final sum = all.fold<double>(0, (acc, t) => acc + t.progress);
    return (sum / all.length * 100).round();
  }

  /// Porcentaje de tareas que están actualmente en progreso.
  int inProgressPercent(String projectId) {
    final all = _allOf(projectId);
    if (all.isEmpty) return 0;
    final active = all.where((t) => t.status == TaskStatus.inProgress).length;
    return (active / all.length * 100).round();
  }

  // ─── Tareas ───────────────────────────────────────────────────────────────

  String get _userName {
    final name = Get.find<AuthenticationController>().loggedName;
    return name.isEmpty ? 'Tú' : name;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void createTask({
    required String projectId,
    required String title,
    String description = '',
  }) {
    tasks.add(
      ProjectTask(id: _newId(), projectId: projectId, title: title, description: description),
    );
  }

  /// Reserva una tarea pendiente para el usuario activo: pasa a "En progreso".
  void reserveTask(String taskId) {
    _update(taskId, (t) => t.copyWith(status: TaskStatus.inProgress, assignee: _userName));
  }

  /// Guarda descripción y checklist. Si todas las subtareas están hechas la
  /// tarea queda terminada; si estaba terminada y se desmarca alguna, vuelve a
  /// "En progreso".
  void saveTask(String taskId, {required String description, required List<Subtask> subtasks}) {
    _update(taskId, (t) {
      final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.done);
      var status = t.status;
      if (allDone) {
        status = TaskStatus.done;
      } else if (t.status == TaskStatus.done) {
        status = TaskStatus.inProgress;
      }
      return t.copyWith(description: description, subtasks: subtasks, status: status);
    });
  }

  void _update(String taskId, ProjectTask Function(ProjectTask) change) {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    tasks[index] = change(tasks[index]);
  }

  // ─── Comentarios ──────────────────────────────────────────────────────────

  void addComment(String taskId, String body, {String? parentId}) {
    final comment = TaskComment(
      id: _newId(),
      author: _userName,
      body: body,
      createdAt: DateTime.now(),
      userVote: 1,
    );
    _update(taskId, (t) {
      if (parentId == null) return t.copyWith(comments: [comment, ...t.comments]);
      return t.copyWith(
        comments: _mapTree(
          t.comments,
          parentId,
          (c) => c.copyWith(replies: [...c.replies, comment]),
        ),
      );
    });
  }

  /// Vota un comentario. Votar dos veces igual quita el voto, como en Reddit.
  void voteComment(String taskId, String commentId, int direction) {
    _update(taskId, (t) {
      return t.copyWith(
        comments: _mapTree(t.comments, commentId, (c) {
          final next = c.userVote == direction ? 0 : direction;
          return c.copyWith(score: c.score - c.userVote + next, userVote: next);
        }),
      );
    });
  }

  List<TaskComment> _mapTree(
    List<TaskComment> list,
    String id,
    TaskComment Function(TaskComment) change,
  ) => [
    for (final c in list)
      if (c.id == id) change(c) else c.copyWith(replies: _mapTree(c.replies, id, change)),
  ];

  // ─── Información del proyecto ─────────────────────────────────────────────

  /// Guarda la información básica. Devuelve null si salió bien o el mensaje de
  /// error para mostrar en pantalla.
  Future<String?> saveProjectInfo({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
  }) async {
    final project = selectedProject.value;
    if (project == null) return 'No hay un proyecto seleccionado.';
    try {
      isSavingProject.value = true;
      await Get.find<IProjectRepository>().updateProject(
        id: project.id,
        title: title,
        description: description,
        jobs: jobs,
        skills: skills,
      );
      final updated = project.copyWith(
        title: title,
        description: description,
        jobs: jobs,
        skills: skills,
      );
      selectedProject.value = updated;
      final owned = Get.find<UserProjectsController>().coCreatedProjects;
      final index = owned.indexWhere((p) => p.id == project.id);
      if (index != -1) owned[index] = updated;
      return null;
    } on ProjectFailure catch (e) {
      return e.message;
    } catch (_) {
      return 'No se pudieron guardar los cambios.';
    } finally {
      isSavingProject.value = false;
    }
  }

  // ─── Ejemplo ──────────────────────────────────────────────────────────────

  /// Siembra una tarea de ejemplo (la del prototipo de Figma) la primera vez
  /// que se abre un proyecto, hasta que exista una tabla de tareas real.
  void _seedExampleTask(String projectId) {
    if (!_seededProjects.add(projectId)) return;
    if (_allOf(projectId).isNotEmpty) return;
    final now = DateTime.now();
    tasks.add(
      ProjectTask(
        id: 'example-$projectId',
        projectId: projectId,
        title: 'Implementación Roble para autenticación',
        description:
            'Integrar el SDK de Roble para el inicio de sesión, el registro y el manejo de la sesión del usuario.',
        subtasks: const [
          Subtask(title: 'Importar librerías', done: true),
          Subtask(title: 'Implementar GET', done: true),
          Subtask(title: 'Implementar POST'),
          Subtask(title: 'Implementar PUT'),
          Subtask(title: 'Implementar DELETE'),
        ],
        comments: [
          TaskComment(
            id: 'example-c1',
            author: 'Laura Gómez',
            body: '¿Ya definimos qué tablas vamos a necesitar para esto?',
            createdAt: now.subtract(const Duration(hours: 5)),
            score: 4,
            replies: [
              TaskComment(
                id: 'example-c1-r1',
                author: 'Pedro Jiménez',
                body: 'Por ahora solo user_system y profile. Lo demás lo vemos en la reunión.',
                createdAt: now.subtract(const Duration(hours: 3)),
                score: 2,
              ),
            ],
          ),
          TaskComment(
            id: 'example-c2',
            author: 'Alberto Mendoza',
            body: 'Recuerden manejar el refresh del token antes de hacer las pruebas.',
            createdAt: now.subtract(const Duration(days: 1)),
            score: 7,
          ),
        ],
      ),
    );
  }
}
