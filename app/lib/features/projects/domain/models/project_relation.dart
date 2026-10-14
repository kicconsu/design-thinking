/// Cómo se relaciona una persona con un proyecto, con una sola respuesta.
///
/// Una persona y un proyecto pueden tener a la vez un guardado, una
/// postulación, una invitación y una membresía. Para que ninguna pantalla
/// calcule esto por su cuenta, la relación es la primera que se cumpla en
/// este orden: [owner] > [active] > [invited] > [pending] > [saved] > [none].
enum ProjectRelation {
  /// Creó el proyecto.
  owner,

  /// Colabora hoy (fila de `project_member` activa).
  active,

  /// Tiene una invitación pendiente y todavía no la respondió.
  invited,

  /// Postuló y espera la decisión del dueño.
  pending,

  /// Solo lo guardó.
  saved,

  /// Nada: puede guardar y postular. También quien salió o fue echado.
  none,
}
