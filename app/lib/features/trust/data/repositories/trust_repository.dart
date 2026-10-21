import 'package:roble/roble.dart';

import '../../domain/models/trust_metrics.dart';
import '../../domain/repositories/i_trust_repository.dart';
import '../../domain/trust_failure.dart';
import '../datasources/i_trust_data_source.dart';

class TrustRepository implements ITrustRepository {
  TrustRepository(this._source);

  final ITrustDataSource _source;

  @override
  Future<TrustMetrics> getTrustMetricsOf(String userId) async {
    if (userId.isEmpty) return TrustMetrics.none;
    // Las dos consultas salen a la vez. `Future.wait` de lista (y no de record)
    // deja pasar la excepción original, que `_guard` sabe traducir.
    final [participations, deliveries] = await _guard(
      () => Future.wait([
        _source.readParticipations([userId]),
        _source.readDeliveries([userId]),
      ]),
    );
    return TrustMetrics.calculate(
      participations: participations.map(_toParticipation),
      deliveries: _toDeliveries(deliveries.firstOrNull),
    );
  }

  @override
  Future<Map<String, int>> getCommitmentScores(Iterable<String> userIds) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const {};
    // Dos consultas para todas las personas, no una por persona.
    final [participationRows, deliveryRows] = await _guard(
      () => Future.wait([
        _source.readParticipations(ids),
        _source.readDeliveries(ids),
      ]),
    );

    final participationsByUser = <String, List<ProjectParticipation>>{};
    for (final row in participationRows) {
      final userId = row['user_id']?.toString() ?? '';
      if (userId.isEmpty) continue;
      participationsByUser
          .putIfAbsent(userId, () => [])
          .add(_toParticipation(row));
    }
    final deliveriesByUser = {
      for (final row in deliveryRows)
        if (row['user_id']?.toString() case final id? when id.isNotEmpty)
          id: _toDeliveries(row),
    };

    final scores = <String, int>{};
    for (final entry in participationsByUser.entries) {
      final metrics = TrustMetrics.calculate(
        participations: entry.value,
        deliveries: deliveriesByUser[entry.key] ?? const OnTimeDeliveries(),
      );
      if (metrics.commitment case final score?) scores[entry.key] = score;
    }
    return scores;
  }

  // ─── Mappers ──────────────────────────────────────────────────────────────
  // Roble devuelve los `numeric` y `bigint` como texto ("0") y los `float8`
  // como número: se lee todo por su texto.

  ProjectParticipation _toParticipation(Map<String, dynamic> row) =>
      ProjectParticipation(
        projectId: row['project_id']?.toString() ?? '',
        tasksFinished: _int(row['tasks_finished']),
        tasksTaken: _int(row['tasks_taken']),
        totalTasks: _int(row['total_tasks']),
        progress: _num(row['progress']).toDouble(),
      );

  OnTimeDeliveries _toDeliveries(Map<String, dynamic>? row) => row == null
      ? const OnTimeDeliveries()
      : OnTimeDeliveries(
          withDeadline: _int(row['con_deadline']),
          onTime: _int(row['a_tiempo']),
        );

  num _num(Object? value) => num.tryParse(value?.toString() ?? '') ?? 0;

  int _int(Object? value) => _num(value).toInt();

  // ─── Traducción de errores ────────────────────────────────────────────────
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RobleApiNetworkException {
      throw const TrustFailure('Sin conexión. Verifica tu red.');
    } on RobleApiTimeoutException {
      throw const TrustFailure(
        'La solicitud tardó demasiado. Intenta de nuevo.',
      );
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 403) {
        throw const TrustFailure('No tienes permiso para ver estos datos.');
      }
      throw TrustFailure(e.message);
    } on RobleApiException catch (e) {
      throw TrustFailure(e.message);
    }
  }
}
