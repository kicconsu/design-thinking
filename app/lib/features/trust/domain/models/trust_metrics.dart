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

  bool get isCompleted => progress >= 100;
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
/// Salen de su historial de colaboración; sin historial valen 0 y no se
/// muestran (ver [hasHistory]).
class TrustMetrics {
  const TrustMetrics({
    this.commitment = 0,
    this.onTime = 0,
    this.responseRate = 0,
    this.completedProjects = 0,
  });

  /// Sin historial: nada que mostrar.
  static const none = TrustMetrics();

  /// Índice general de compromiso: promedio, entre los proyectos en los que
  /// participó, de lo que terminó frente al total de tareas del proyecto.
  final int commitment;

  /// Entrega a tiempo: de las tareas terminadas con fecha límite, las que se
  /// terminaron antes de ella.
  final int onTime;

  /// Tasa de respuesta: promedio, entre proyectos, de lo que terminó frente a
  /// lo que tomó.
  final int responseRate;

  /// Proyectos completados: de aquellos en los que participó, los que están
  /// al 100 %.
  final int completedProjects;

  /// Mismo criterio que `UserProfile.hasTrustHistory`.
  bool get hasHistory => commitment > 0;

  /// Calcula los cuatro indicadores. Un proyecto sin denominador (sin tareas,
  /// o sin tareas tomadas) no entra en el promedio que lo necesita: no es un 0.
  static TrustMetrics calculate({
    required Iterable<ProjectParticipation> participations,
    OnTimeDeliveries deliveries = const OnTimeDeliveries(),
  }) {
    final list = participations.toList();
    return TrustMetrics(
      commitment: commitmentOf(list),
      onTime: _percent(deliveries.onTime, deliveries.withDeadline),
      responseRate: _averagePercent([
        for (final p in list)
          if (p.tasksTaken > 0) p.tasksFinished / p.tasksTaken,
      ]),
      completedProjects: _percent(
        list.where((p) => p.isCompleted).length,
        list.length,
      ),
    );
  }

  /// Solo el índice general de compromiso (lo que muestra la lista de
  /// solicitudes).
  static int commitmentOf(Iterable<ProjectParticipation> participations) =>
      _averagePercent([
        for (final p in participations)
          if (p.totalTasks > 0) p.tasksFinished / p.totalTasks,
      ]);

  static int _percent(int part, int whole) =>
      whole <= 0 ? 0 : _clamp(part / whole);

  static int _averagePercent(List<double> ratios) {
    if (ratios.isEmpty) return 0;
    return _clamp(ratios.reduce((a, b) => a + b) / ratios.length);
  }

  /// Cada razón se acota a 100 % antes de promediar: un contador desfasado no
  /// puede pasarse de lo posible.
  static int _clamp(double ratio) => (ratio.clamp(0.0, 1.0) * 100).round();
}
