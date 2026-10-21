import 'dart:async';

import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:roble/roble.dart';

/// Fuente de proyectos en memoria a la que una prueba le puede dar guion:
///
/// - perfiles con nombre (el nombre es «Nombre de» más el id), con casos para `roto` (lanza) y
///   `sin-perfil` (null);
/// - fallos en las próximas respuestas a una solicitud o a una invitación
///   ([joinRequestFailures], [invitationFailures]): fallan esa cantidad de
///   veces con un 404 y luego responden normal (permite probar reintentos);
/// - lecturas que esperan a que la prueba las libere ([invitationsGate],
///   [joinRequestsGate]), para ver qué pasa cuando la respuesta llega tarde.
class ScriptedProjectDataSource extends InMemoryProjectDataSource {
  ScriptedProjectDataSource([super.projects, super.clock]);

  int joinRequestFailures = 0;
  int invitationFailures = 0;
  Completer<void>? invitationsGate;
  Completer<void>? joinRequestsGate;

  @override
  Future<Map<String, dynamic>?> readUserProfile(String userId) async {
    if (userId == 'roto') throw StateError('sin permiso');
    if (userId == 'sin-perfil') return null;
    return {
      'name': 'Nombre de $userId',
      'career': {'program': 'Ingeniería', 'institution': 'Uninorte'},
    };
  }

  @override
  Future<Map<String, dynamic>> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    if (joinRequestFailures > 0) {
      joinRequestFailures--;
      throw const RobleApiHttpException(404, 'Not found');
    }
    return super.updateJoinRequestStatus(
      requestId: requestId,
      status: status,
      reviewedBy: reviewedBy,
      reviewNote: reviewNote,
    );
  }

  @override
  Future<Map<String, dynamic>> updateInvitationStatus({
    required String invitationId,
    required String status,
  }) async {
    if (invitationFailures > 0) {
      invitationFailures--;
      throw const RobleApiHttpException(404, 'Not found');
    }
    return super.updateInvitationStatus(
      invitationId: invitationId,
      status: status,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> readInvitationsForUser(
    String userId,
  ) async {
    await invitationsGate?.future;
    return super.readInvitationsForUser(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> readJoinRequestsByUser(
    String userId,
  ) async {
    await joinRequestsGate?.future;
    return super.readJoinRequestsByUser(userId);
  }
}
