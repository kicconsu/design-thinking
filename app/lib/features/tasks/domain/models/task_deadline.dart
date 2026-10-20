import 'project_task.dart';

/// Reglas de la fecha límite (`deadline`) de una tarea.
///
/// La persona elige un **día**; la fecha límite es el final de ese día en la
/// hora local del dispositivo, guardado como instante UTC. Así, entregar
/// cualquier hora del día elegido cuenta como a tiempo.
class TaskDeadline {
  const TaskDeadline._();

  /// El instante UTC en que termina [day] (solo importa su año, mes y día)
  /// en la zona horaria local.
  static DateTime endOfDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, 23, 59, 59, 999).toUtc();

  /// Quién puede cambiar o quitar la fecha límite de [task]: quien la creó y
  /// el creador del proyecto, mientras la tarea no esté terminada.
  static bool canEdit({
    required ProjectTask task,
    required String userId,
    required String projectOwnerId,
  }) {
    if (task.isDone || userId.isEmpty) return false;
    return userId == task.creatorId || userId == projectOwnerId;
  }

  /// «dd/MM/aaaa» del día local de [instant].
  static String formatDay(DateTime instant) {
    final day = instant.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(day.day)}/${two(day.month)}/${day.year}';
  }

  /// El texto del comentario automático que deja un cambio de fecha límite
  /// (así el equipo ve quién la movió y de cuándo a cuándo).
  static String changeNote({DateTime? before, DateTime? after}) {
    if (before == null && after != null) {
      return 'Fecha límite fijada: ${formatDay(after)}.';
    }
    if (before != null && after == null) {
      return 'Fecha límite quitada (era ${formatDay(before)}).';
    }
    return 'Fecha límite cambiada: ${formatDay(before!)} → ${formatDay(after!)}.';
  }
}
