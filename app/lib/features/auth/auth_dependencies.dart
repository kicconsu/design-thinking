import 'package:get/get.dart';

import 'package:imker/core/data/dummy_auth_source.dart';
import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/core/roble/roble_config.dart';

import 'data/datasources/remote/roble_auth_data_source.dart';
import 'data/datasources/remote/i_authentication_source.dart';
import 'data/repositories/auth_repository.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'ui/viewmodels/authentication_controller.dart';

/// Registra la cadena de dependencias de autenticación con GetX.
///
/// Sin contrato de Roble no hay backend, y se usa la fuente en memoria.
void registerAuth() {
  final IAuthenticationSource source = RobleConfig.contractId.isEmpty
      ? DummyAuthSource()
      : AuthenticationSourceService(Get.find<RobleClient>());

  Get.put<IAuthenticationSource>(source, permanent: true);
  Get.put<IAuthRepository>(AuthRepository(Get.find()), permanent: true);
  Get.put(AuthenticationController(Get.find()), permanent: true);
}
