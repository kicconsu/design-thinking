import 'package:imker/core/roble/roble_client.dart';

import 'i_trust_data_source.dart';

/// Lee las métricas con consultas guardadas en la consola de Roble. Cada una
/// recibe los ids separados por coma en un solo parámetro (no depende de cómo
/// Roble ate arreglos):
///
/// `metricas_compromiso_por_proyecto`
///   SELECT m.user_id, m.project_id,
///          COALESCE(SUM(m.tasks_finished), 0) AS tasks_finished,
///          COALESCE(SUM(m.tasks_taken), 0)    AS tasks_taken,
///          p.total_tasks, p.progress
///   FROM project_member m JOIN project p ON p._id = m.project_id
///   WHERE m.user_id = ANY(string_to_array($1, ',')::uuid[])
///   GROUP BY m.user_id, m.project_id, p.total_tasks, p.progress
///
/// `entregas_a_tiempo`
///   SELECT assignee_id AS user_id,
///     COUNT(*) FILTER (WHERE finished_at IS NOT NULL
///                      AND deadline IS NOT NULL) AS con_deadline,
///     COUNT(*) FILTER (WHERE finished_at <= deadline) AS a_tiempo
///   FROM task
///   WHERE assignee_id = ANY(string_to_array($1, ',')::uuid[])
///     AND status = 'done'
///   GROUP BY assignee_id
///
/// Si una no existe o está apagada, la excepción se propaga: mejor sin
/// métricas que con unas falsas.
class RobleTrustDataSource implements ITrustDataSource {
  RobleTrustDataSource(this._client);

  final RobleClient _client;

  static const participationsQuery = 'metricas_compromiso_por_proyecto';
  static const deliveriesQuery = 'entregas_a_tiempo';

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  Future<List<Map<String, dynamic>>> readParticipations(List<String> userIds) =>
      _run(participationsQuery, userIds);

  @override
  Future<List<Map<String, dynamic>>> readDeliveries(List<String> userIds) =>
      _run(deliveriesQuery, userIds);

  Future<List<Map<String, dynamic>>> _run(
    String query,
    List<String> userIds,
  ) async {
    // Un id que no sea uuid tumbaría la consulta entera (el cast falla): se
    // descarta aquí y esa persona simplemente no tiene historial.
    final ids = userIds.where(_uuid.hasMatch).toSet();
    if (ids.isEmpty) return const [];
    final result = await _client.db.executeQueryByName(
      query,
      params: [ids.join(',')],
    );
    return [
      for (final row in result.rows)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }
}
