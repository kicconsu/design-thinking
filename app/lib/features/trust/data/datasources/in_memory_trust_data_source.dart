import 'i_trust_data_source.dart';

/// Fuente en memoria: modo sin contrato y pruebas. Se siembra con filas de la
/// misma forma que devolverían las consultas de Roble.
class InMemoryTrustDataSource implements ITrustDataSource {
  final List<Map<String, dynamic>> participations = [];
  final List<Map<String, dynamic>> deliveries = [];

  /// Cuántas veces se consultó cada una, para probar que no se repiten.
  int participationReads = 0;
  int deliveryReads = 0;

  @override
  Future<List<Map<String, dynamic>>> readParticipations(
    List<String> userIds,
  ) async {
    participationReads++;
    return [
      for (final r in participations)
        if (userIds.contains(r['user_id'])) Map<String, dynamic>.from(r),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> readDeliveries(
    List<String> userIds,
  ) async {
    deliveryReads++;
    return [
      for (final r in deliveries)
        if (userIds.contains(r['user_id'])) Map<String, dynamic>.from(r),
    ];
  }
}
