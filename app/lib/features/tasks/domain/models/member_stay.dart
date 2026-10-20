/// Una estancia de una persona en un proyecto (una fila de `project_member`)
/// con sus contadores de tareas.
///
/// Salir y volver crea una fila nueva, así que una persona puede tener varias
/// estancias en el mismo proyecto. Los contadores de cada una son lo que
/// sumó *durante* esa estancia: quien lee las métricas las suma todas.
class MemberStay {
  const MemberStay({
    required this.id,
    this.isActive = true,
    this.joinedAt,
    this.taken = 0,
    this.finished = 0,
  });

  final String id;
  final bool isActive;
  final DateTime? joinedAt;

  /// Tareas que tomó en esta estancia. Las que soltó al salir siguen contando.
  final int taken;

  /// Tareas que terminó en esta estancia.
  final int finished;

  /// La estancia donde se anota lo nuevo: la activa; si ninguna lo está (p.
  /// ej. se reabre una tarea de alguien que ya salió), la más reciente.
  /// Null si no hay ninguna.
  static MemberStay? current(Iterable<MemberStay> stays) {
    MemberStay? best;
    for (final stay in stays) {
      if (best == null || _isNewer(stay, best)) best = stay;
    }
    return best;
  }

  static bool _isNewer(MemberStay a, MemberStay b) {
    if (a.isActive != b.isActive) return a.isActive;
    final ad = a.joinedAt;
    final bd = b.joinedAt;
    if (ad == null || bd == null) return ad != null;
    return ad.isAfter(bd);
  }

  /// Cuántas terminadas anotar en [current], dado que [totalFinished] es lo
  /// que la persona tiene terminado en todo el proyecto (todas sus estancias):
  /// el total menos lo que ya anotaron las demás. Nunca negativo.
  static int finishedFor(
    MemberStay current,
    Iterable<MemberStay> all,
    int totalFinished,
  ) {
    var others = 0;
    for (final stay in all) {
      if (stay.id != current.id) others += stay.finished;
    }
    final mine = totalFinished - others;
    return mine < 0 ? 0 : mine;
  }
}
