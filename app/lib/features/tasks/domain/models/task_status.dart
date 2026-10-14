/// Estado de una tarea, con el texto en español que se le muestra a la gente.
///
/// En la base de datos el valor sigue siendo `todo` / `doing` / `done`: este
/// enum sólo traduce para la UI.
enum TaskStatus {
  todo('Pendiente'),
  doing('En progreso'),
  done('Terminada');

  const TaskStatus(this.label);
  final String label;

  /// Un estado que la app no conoce no puede tumbar la lista: se trata como
  /// pendiente, que es también el estado con el que nace una tarea.
  static TaskStatus fromName(String? name) => TaskStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => TaskStatus.todo,
  );
}
