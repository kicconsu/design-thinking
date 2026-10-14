import 'package:get/get.dart';

import 'roble_client.dart';
import 'roble_config.dart';

/// `user_id` de quien tiene la sesión: el `sub` del token, que es también el
/// `_owner` de sus filas. Vacío si no hay sesión. Sin contrato (modo mock) es
/// `demo-user`, el mismo que usan las fuentes en memoria.
String sessionUserId() {
  if (RobleConfig.contractId.isEmpty) return 'demo-user';
  if (!Get.isRegistered<RobleClient>()) return '';
  return Get.find<RobleClient>().currentUserId ?? '';
}
