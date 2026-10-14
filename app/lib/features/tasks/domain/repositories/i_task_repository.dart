import '../models/project_task.dart';
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

  /// Borra la tarea y recalcula el progreso del proyecto.
  Future<void> deleteTask(ProjectTask task);

  /// Vuelve a contar las tareas del proyecto y guarda el porcentaje en
  /// `project.progress`. Devuelve el valor calculado.
  ///
  /// Siempre cuenta desde cero, nunca suma ni resta sobre lo guardado: si dos
  /// personas cambian tareas a la vez, la siguiente llamada lo corrige sola.
  Future<double> recalculateProgress(String projectId);
}
