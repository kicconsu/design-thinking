/// Lo que una persona hizo en un proyecto: sus tareas terminadas y tomadas
/// (sumadas entre todas sus estancias) frente al total del proyecto.
class ProjectParticipation {
  const ProjectParticipation({
    required this.projectId,
    this.tasksFinished = 0,
    this.tasksTaken = 0,
    this.totalTasks = 0,
    this.progress = 0,
  });

  final String projectId;
  final int tasksFinished;
  final int tasksTaken;

  /// Tareas del proyecto entero (no solo las de esta persona).
  final int totalTasks;

  /// Avance del proyecto, 0–100.
  final double progress;

  /// Un proyecto sin tareas no está «completado»: no hay trabajo que haya
  /// terminado, aunque su avance figure en 100.
  bool get isCompleted => totalTasks > 0 && progress >= 100;
}

/// Entregas de una persona con fecha límite: cuántas tenían deadline y
/// cuántas se terminaron a tiempo.
class OnTimeDeliveries {
  const OnTimeDeliveries({this.withDeadline = 0, this.onTime = 0});

  final int withDeadline;
  final int onTime;
}

/// Indicadores de confianza de una persona, cada uno de 0 a 100.
///
/// Un indicador es `null` cuando no hay de dónde sacarlo (su denominador es
/// 0): eso es "sin datos", no un 0 %. Un 0 significa "hizo 0 de N con N > 0".
/// Ver `plan-finalizacion-imker/05-especificacion-confianza.md`.
class TrustMetrics {
  const TrustMetrics({
    this.commitment,
    this.onTime,
    this.fulfillment,
    this.completedProjects,
    this.hasHistory = false,
  });

  /// Sin historial: nada que mostrar.
  static const none = TrustMetrics();

  /// Índice general de compromiso: promedio de los indicadores base que tienen
  /// datos. Nulo si ninguno los tiene.
  final int? commitment;

  /// Entrega a tiempo: de las tareas terminadas con fecha límite, las que se
  /// terminaron a tiempo (`finished_at <= deadline`). Lo no entregado no cuenta
  /// aquí: lo capta [fulfillment].
  final int? onTime;

  /// Cumplimiento: de las tareas que tomó, cuántas terminó. Promedio entre los
  /// proyectos donde tomó alguna.
  final int? fulfillment;

  /// Proyectos completados: de aquellos en los que participó, los que están al
  /// 100 %.
  final int? completedProjects;

  /// Participó en al menos un proyecto (aunque algún indicador no tenga datos).
  final bool hasHistory;

  /// Calcula los indicadores. Todas las razones se acotan a [0, 1] y se
  /// promedian sin redondear; el redondeo es solo de presentación.
  static TrustMetrics calculate({
    required Iterable<ProjectParticipation> participations,
    OnTimeDeliveries deliveries = const OnTimeDeliveries(),
  }) {
    final list = participations.toList();
    if (list.isEmpty) return none;

    final fulfillment = _average([
      for (final p in list)
        if (p.tasksTaken > 0) _ratio(p.tasksFinished, p.tasksTaken)!,
    ]);
    final onTime = _ratio(deliveries.onTime, deliveries.withDeadline);
    final completed = _ratio(
      list.where((p) => p.isCompleted).length,
      list.length,
    );

    return TrustMetrics(
      commitment: _percent(_average([?fulfillment, ?onTime, ?completed])),
      onTime: _percent(onTime),
      fulfillment: _percent(fulfillment),
      completedProjects: _percent(completed),
      hasHistory: true,
    );
  }

  /// `part / whole` acotado a [0, 1]; nulo si no hay nada que dividir.
  static double? _ratio(int part, int whole) =>
      whole <= 0 ? null : (part / whole).clamp(0.0, 1.0);

  static double? _average(List<double> ratios) =>
      ratios.isEmpty ? null : ratios.reduce((a, b) => a + b) / ratios.length;

  static int? _percent(double? ratio) =>
      ratio == null ? null : (ratio * 100).round();
}
