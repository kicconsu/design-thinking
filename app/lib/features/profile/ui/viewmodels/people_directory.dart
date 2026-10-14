import 'package:get/get.dart';

import '../../domain/repositories/i_profile_repository.dart';

/// Lo mínimo para nombrar a una persona en una lista.
class PersonSummary {
  const PersonSummary({required this.name, this.career = ''});

  final String name;

  /// "Programa - Institución"; vacío si no lo llenó.
  final String career;
}

/// Caché de sesión de nombres: «quién es» cada `user_id` que aparece en una
/// pantalla (quien te invitó, p. ej.), con una sola lectura por persona aunque
/// salga en muchas tarjetas. Una instancia para toda la app; auth la vacía al
/// salir.
class PeopleDirectory extends GetxController {
  final RxMap<String, PersonSummary> _people = <String, PersonSummary>{}.obs;
  final Map<String, Future<PersonSummary?>> _inflight = {};

  /// Cambia al vaciar: una lectura de la sesión anterior no escribe en la nueva.
  int _epoch = 0;

  /// Lo que ya se sabe de [userId] (reactivo); null si todavía no se leyó.
  PersonSummary? summaryOf(String userId) => _people[userId];

  /// Lee a [userId] si hace falta. Devuelve null si no se pudo (sin sesión real,
  /// sin permiso o sin red); no recuerda el fallo, así que se puede reintentar.
  Future<PersonSummary?> load(String userId) {
    if (userId.isEmpty) return Future.value(null);
    final known = _people[userId];
    if (known != null) return Future.value(known);
    return _inflight[userId] ??= _read(userId);
  }

  Future<PersonSummary?> _read(String userId) async {
    final epoch = _epoch;
    try {
      final profile = await Get.find<IProfileRepository>().getProfileOf(
        userId,
      );
      final summary = PersonSummary(
        name: profile.name.isNotEmpty ? profile.name : 'Usuario',
        career: profile.academicInfo,
      );
      if (epoch == _epoch) _people[userId] = summary;
      return summary;
    } catch (_) {
      return null;
    } finally {
      if (epoch == _epoch) _inflight.remove(userId);
    }
  }

  /// Olvida lo de la sesión que se va.
  void clear() {
    _epoch++;
    _people.clear();
    _inflight.clear();
  }
}
