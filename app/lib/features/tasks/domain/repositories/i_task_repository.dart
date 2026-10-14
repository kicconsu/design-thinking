import '../models/project_task.dart';
import '../models/subtask.dart';
import '../models/task_comment.dart';
import '../models/task_status.dart';

abstract class ITaskRepository {
  Future<List<ProjectTask>> getTasks(String projectId);

  /// Crea la tarea (siempre `todo`) y recalcula el progreso del proyecto.
  Future<ProjectTask> createTask({
    required String projectId,
    required String title,
    String description = '',
  });

  /// Cambia el estado y recalcula el progreso del proyecto.
  Future<ProjectTask> updateTaskStatus({
    required ProjectTask task,
    required TaskStatus status,
  });

  /// Reserva una tarea pendiente para [userId]: queda `doing` con esa persona
  /// como responsable. Lee la tarea justo antes de escribir y, si otra persona
  /// ya la tomó, lanza `ProjectFailure` en vez de pisarla.
  ///
  /// Roble no tiene escrituras condicionales: esto reduce la ventana de
  /// carrera, pero no la elimina del todo.
  Future<ProjectTask> reserveTask({
    required ProjectTask task,
    required String userId,
  });

  /// Guarda descripción y checklist en una sola escritura. El estado lo
  /// decide [ProjectTask.statusAfterSaving]; si cambia, se recalcula el
  /// progreso del proyecto. Devuelve la tarea ya con los valores guardados.
  Future<ProjectTask> saveTaskProgress({
    required ProjectTask task,
    required String description,
    required List<Subtask> subtasks,
  });

  /// Comentarios de la tarea, del más nuevo al más viejo.
  Future<List<TaskComment>> getComments(ProjectTask task);

  /// Agrega un comentario de [userId] a la tarea.
  Future<TaskComment> addComment({
    required ProjectTask task,
    required String userId,
    required String body,
  });

  /// Borra la tarea y recalcula el progreso del proyecto.
  Future<void> deleteTask(ProjectTask task);

  /// Vuelve a contar las tareas del proyecto y guarda el porcentaje en
  /// `project.progress`. Devuelve el valor calculado.
  ///
  /// Siempre cuenta desde cero, nunca suma ni resta sobre lo guardado: si dos
  /// personas cambian tareas a la vez, la siguiente llamada lo corrige sola.
  Future<double> recalculateProgress(String projectId);
}
