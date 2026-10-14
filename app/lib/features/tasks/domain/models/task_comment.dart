/// Comentario de una tarea: una fila de `contribution`.
///
/// Es plano: la tabla no guarda respuestas ni votos.
class TaskComment {
  const TaskComment({
    required this.id,
    required this.userId,
    required this.body,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String body;
  final DateTime? createdAt;
}
