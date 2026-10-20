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
}
