import 'subtask.dart';
import 'task_status.dart';

/// Entidad del dominio: una tarea de un proyecto (`task`).
class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.assigneeId,
    this.subtasks = const [],
    this.deadline,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;

  /// `user_id` de quien reservó la tarea; null mientras nadie la tomó.
  final String? assigneeId;

  /// Checklist de progreso de la tarea.
  final List<Subtask> subtasks;

  /// Instante UTC en que vence la tarea (ver `TaskDeadline`); null si no tiene
  /// fecha límite.
  final DateTime? deadline;

  bool get isDone => status == TaskStatus.done;

  /// Avance del checklist entre 0 y 1; 0 si no hay subtareas.
  double get checklistProgress {
    if (subtasks.isEmpty) return 0;
    return subtasks.where((s) => s.done).length / subtasks.length;
  }

  ProjectTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    String? assigneeId,
    List<Subtask>? subtasks,
    DateTime? deadline,
    bool clearDeadline = false,
  }) {
    return ProjectTask(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      subtasks: subtasks ?? this.subtasks,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
    );
  }

  /// Estado en el que queda una tarea al guardar su checklist: con todas las
  /// subtareas hechas pasa a terminada; si estaba terminada y se desmarca
  /// alguna, vuelve a en progreso; en cualquier otro caso no cambia.
  static TaskStatus statusAfterSaving(
    TaskStatus current,
    List<Subtask> subtasks,
  ) {
    final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.done);
    if (allDone) return TaskStatus.done;
    if (current == TaskStatus.done) return TaskStatus.doing;
    return current;
  }

  /// Porcentaje (0–100) de [tasks] terminadas. Un proyecto sin tareas está en
  /// 0, no es un error: así nunca se divide entre cero.
  static double progressOf(Iterable<ProjectTask> tasks) {
    var total = 0;
    var done = 0;
    for (final task in tasks) {
      total++;
      if (task.isDone) done++;
    }
    return total == 0 ? 0 : done * 100 / total;
  }

  @override
  String toString() => 'ProjectTask(id: $id, title: $title, status: $status)';
}
