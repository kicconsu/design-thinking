import 'dart:async';

import 'package:imker/features/trust/domain/models/trust_metrics.dart';
import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

/// Repositorio de confianza para pruebas: devuelve [metrics] (o lanza
/// [failure]) y recuerda a quién se le pidió. Con [gate] la respuesta espera
/// a que la prueba la libere, para ver el estado de carga.
class FakeTrustRepository implements ITrustRepository {
  TrustMetrics metrics = const TrustMetrics(
    commitment: 72,
    onTime: 80,
    fulfillment: 65,
    completedProjects: 50,
    hasHistory: true,
  );
  Map<String, int> scores = {};
  TrustFailure? failure;
  Completer<void>? gate;

  /// A quién se le pidieron los indicadores, en orden.
  final metricsAsked = <String>[];
  final scoresAsked = <List<String>>[];

  @override
  Future<TrustMetrics> getTrustMetricsOf(String userId) async {
    metricsAsked.add(userId);
    await gate?.future;
    if (failure != null) throw failure!;
    return metrics;
  }

  @override
  Future<Map<String, int>> getCommitmentScores(Iterable<String> userIds) async {
    scoresAsked.add(userIds.toList());
    if (failure != null) throw failure!;
    return scores;
  }
}
