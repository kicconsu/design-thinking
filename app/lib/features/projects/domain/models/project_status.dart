/// Estado de un proyecto, con el texto en español que se le muestra a la gente.
///
/// En la base de datos el valor sigue siendo `open` / `closed`: este enum sólo
/// traduce para la UI y nunca se serializa.
enum ProjectStatus {
  open('Abierto'),
  closed('Cerrado');

  const ProjectStatus(this.label);
  final String label;

  /// Un estado que la app no conoce no puede tumbar la lista: se muestra como
  /// abierto, que es además el estado por defecto al crear un proyecto.
  static ProjectStatus fromName(String? name) => ProjectStatus.values
      .firstWhere((s) => s.name == name, orElse: () => ProjectStatus.open);
}
