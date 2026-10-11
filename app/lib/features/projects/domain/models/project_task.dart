/// Estado de una tarea dentro del gabinete de tareas de un proyecto.
enum TaskStatus { pending, inProgress, done }

/// Ítem del checklist de progreso de una tarea.
class Subtask {
  const Subtask({required this.title, this.done = false});

  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(title: title ?? this.title, done: done ?? this.done);
}

/// Comentario de una tarea. Es un árbol estilo Reddit: cada comentario puede
/// tener respuestas anidadas.
class TaskComment {
  const TaskComment({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    this.score = 1,
    this.userVote = 0,
    this.replies = const [],
  });

  final String id;
  final String author;
  final String body;
  final DateTime createdAt;

  /// Puntaje total (votos a favor menos votos en contra).
  final int score;

  /// Voto del usuario activo: 1 a favor, -1 en contra, 0 sin voto.
  final int userVote;
  final List<TaskComment> replies;

  /// Cantidad de comentarios en este hilo, contándose a sí mismo.
  int get threadSize => 1 + replies.fold<int>(0, (sum, r) => sum + r.threadSize);

  TaskComment copyWith({int? score, int? userVote, List<TaskComment>? replies}) =>
      TaskComment(
        id: id,
        author: author,
        body: body,
        createdAt: createdAt,
        score: score ?? this.score,
        userVote: userVote ?? this.userVote,
        replies: replies ?? this.replies,
      );
}

/// Una tarea del gabinete de un proyecto.
class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.pending,
    this.assignee,
    this.subtasks = const [],
    this.comments = const [],
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;

  /// Quién reservó la tarea (null mientras está pendiente).
  final String? assignee;
  final List<Subtask> subtasks;
  final List<TaskComment> comments;

  /// Avance de la tarea entre 0 y 1: completa si está terminada; si no, la
  /// fracción de subtareas hechas.
  double get progress {
    if (status == TaskStatus.done) return 1;
    if (subtasks.isEmpty) return 0;
    return subtasks.where((s) => s.done).length / subtasks.length;
  }

  ProjectTask copyWith({
    String? description,
    TaskStatus? status,
    String? assignee,
    List<Subtask>? subtasks,
    List<TaskComment>? comments,
  }) => ProjectTask(
    id: id,
    projectId: projectId,
    title: title,
    description: description ?? this.description,
    status: status ?? this.status,
    assignee: assignee ?? this.assignee,
    subtasks: subtasks ?? this.subtasks,
    comments: comments ?? this.comments,
  );
}
