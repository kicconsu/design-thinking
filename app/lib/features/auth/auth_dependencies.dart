import 'package:get/get.dart';

import 'package:imker/core/data/dummy_auth_source.dart';
import 'package:imker/core/roble/roble_client.dart';
import 'data/datasources/remote/authentication_source_service.dart';
import 'data/datasources/remote/i_authentication_source.dart';
import 'data/repositories/auth_repository.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'ui/viewmodels/authentication_controller.dart';

/// Registra la cadena de dependencias de autenticación con GetX.
void registerAuth() {
  final IAuthenticationSource source = Get.isRegistered<RobleClient>()
      ? AuthenticationSourceService(Get.find<RobleClient>())
      : DummyAuthSource();

  Get.put<IAuthenticationSource>(source, permanent: true);
  Get.put<IAuthRepository>(AuthRepository(Get.find()), permanent: true);
  Get.put(AuthenticationController(Get.find()), permanent: true);
}

