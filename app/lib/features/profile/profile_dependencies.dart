import 'package:get/get.dart';

import '../../core/roble/roble_client.dart';
import '../../core/roble/roble_config.dart';
import 'data/datasources/i_profile_data_source.dart';
import 'data/datasources/in_memory_profile_data_source.dart';
import 'data/datasources/roble_profile_data_source.dart';
import 'data/repositories/profile_repository.dart';
import 'domain/repositories/i_profile_repository.dart';
import 'ui/viewmodels/profile_controller.dart';

/// Datos de perfil, registrados en [main] y permanentes.
///
/// No vive en el binding de Home porque auth los necesita al entrar: es quien
/// garantiza que la fila exista, y se registra antes que el controlador.
void registerProfileData() {
  final useMock = RobleConfig.contractId.isEmpty;

  if (useMock) {
    Get.put<IProfileDataSource>(InMemoryProfileDataSource(), permanent: true);
  } else {
    Get.put<IProfileDataSource>(
      RobleProfileDataSource(Get.find<RobleClient>()),
      permanent: true,
    );
  }

  Get.put<IProfileRepository>(
    ProfileRepository(Get.find<IProfileDataSource>()),
    permanent: true,
  );
}

/// El ViewModel de la pestaña de perfil: se crea al abrir la pantalla.
///
/// `fenix: true` para que, si se borra al cerrar sesión, la siguiente persona
/// encuentre uno nuevo y no el perfil que quedó en memoria del anterior.
void registerProfile() {
  if (!Get.isRegistered<IProfileRepository>()) registerProfileData();
  Get.lazyPut(() => ProfileController(Get.find<IProfileRepository>()), fenix: true);
}
