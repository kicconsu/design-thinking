import '../models/project_task.dart';
import '../models/subtask.dart';
import '../models/task_comment.dart';
import '../models/task_status.dart';

abstract class ITaskRepository {
  Future<List<ProjectTask>> getTasks(String projectId);

  /// Crea la tarea (siempre `todo`) y recalcula el progreso y el total de
  /// tareas del proyecto. [deadline] es opcional (ver `TaskDeadline`).
  Future<ProjectTask> createTask({
    required String projectId,
    required String title,
    String description = '',
    DateTime? deadline,
  });

  /// Cambia el estado y recalcula el progreso del proyecto. Si la tarea tiene
  /// responsable y pasa a (o deja de estar) terminada, recalcula también las
  /// terminadas de esa persona.
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
  ///
  /// Suma una a las tareas tomadas de [userId] en el proyecto, salvo que la
  /// tarea ya fuera suya.
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

  /// Libera las tareas sin terminar (`todo` o `doing`) que tenía [userId]:
  /// quedan sin responsable y vuelven a `todo`. Las terminadas no se tocan:
  /// siguen a nombre de quien las hizo. Devuelve cuántas liberó.
  ///
  /// El progreso del proyecto no cambia (solo cuentan las terminadas) y las
  /// tareas tomadas de [userId] tampoco bajan: lo que soltó sigue contando como
  /// tomado, para que su tasa de respuesta lo refleje.
  Future<int> releaseUnfinishedTasks({
    required String projectId,
    required String userId,
  });

  /// Borra la tarea y recalcula el progreso y el total de tareas del
  /// proyecto. Si tenía responsable, esa persona deja de tenerla como tomada y
  /// se recalculan sus terminadas.
  Future<void> deleteTask(ProjectTask task);

  /// Vuelve a contar las tareas del proyecto y guarda el porcentaje en
  /// `project.progress` y el conteo en `project.total_tasks`. Devuelve el
  /// porcentaje calculado.
  ///
  /// Siempre cuenta desde cero, nunca suma ni resta sobre lo guardado: si dos
  /// personas cambian tareas a la vez, la siguiente llamada lo corrige sola.
  Future<double> recalculateProgress(String projectId);
}
