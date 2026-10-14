import '../models/trust_metrics.dart';

abstract class ITrustRepository {
  /// Los indicadores de confianza de [userId], calculados de su historial de
  /// colaboración. Sin historial, [TrustMetrics.none].
  Future<TrustMetrics> getTrustMetricsOf(String userId);

  /// Índice general de compromiso (0–100) de cada una de [userIds], en una sola
  /// consulta. Quien no tiene historial no aparece en el mapa.
  Future<Map<String, int>> getCommitmentScores(Iterable<String> userIds);
}
