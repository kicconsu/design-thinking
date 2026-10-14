import 'package:get/get.dart';

import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

/// `user_id` -> nombre del perfil, para mostrar quién reservó una tarea o
/// quién comentó. Reactivo: leer [nameOf] dentro de un `Obx` se actualiza
/// cuando llega el nombre.
class UserNameCache {
  final RxMap<String, String> _names = <String, String>{}.obs;

  /// Nombre ya resuelto, o null si todavía no se leyó (o no tiene perfil).
  String? nameOf(String userId) => _names[userId];

  /// Lee los perfiles que falten. Un perfil ilegible se omite: quien muestra
  /// el nombre pone un genérico.
  Future<void> resolve(Iterable<String> userIds) async {
    if (!Get.isRegistered<IProjectRepository>()) return;
    final missing = {
      for (final id in userIds)
        if (id.isNotEmpty && !_names.containsKey(id)) id,
    };
    for (final id in missing) {
      try {
        final profile = await Get.find<IProjectRepository>().getUserProfile(id);
        final name = (profile?['name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty) _names[id] = name;
      } on ProjectFailure {
        // Sin perfil legible queda el nombre genérico.
      }
    }
  }
}
