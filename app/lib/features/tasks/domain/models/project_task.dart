import 'task_status.dart';

/// Entidad del dominio: una tarea de un proyecto (`task`).
class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;

  bool get isDone => status == TaskStatus.done;

  ProjectTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
  }) {
    return ProjectTask(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
    );
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
