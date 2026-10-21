import '../models/trust_metrics.dart';

abstract class ITrustRepository {
  /// Los indicadores de confianza de [userId], calculados de su historial de
  /// colaboración. Sin historial, [TrustMetrics.none].
  Future<TrustMetrics> getTrustMetricsOf(String userId);

  /// Índice general de compromiso (0–100) de cada una de [userIds], con dos
  /// consultas para todas. Quien no tiene historial (o ningún indicador con
  /// datos) no aparece en el mapa; un 0 es un 0 real.
  Future<Map<String, int>> getCommitmentScores(Iterable<String> userIds);
}
