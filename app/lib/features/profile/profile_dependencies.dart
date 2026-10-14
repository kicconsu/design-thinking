import 'package:get/get.dart';

import '../../core/roble/roble_client.dart';
import '../../core/roble/roble_config.dart';
import 'data/datasources/i_profile_data_source.dart';
import 'data/datasources/in_memory_profile_data_source.dart';
import 'data/datasources/roble_profile_data_source.dart';
import 'data/repositories/profile_repository.dart';
import 'domain/repositories/i_profile_repository.dart';
import 'ui/viewmodels/people_directory.dart';
import 'ui/viewmodels/profile_controller.dart';

/// Datos y controlador de perfil, registrados en [main] y permanentes.
///
/// No viven en el binding de Home porque auth los necesita al entrar: es quien
/// garantiza que la fila exista, carga el perfil y lo vacía al salir. Una sola
/// instancia del controlador (registrarla por ruta con `fenix` creaba copias
/// por login, como pasaba con los controllers de proyectos).
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

  Get.put(ProfileController(Get.find<IProfileRepository>()), permanent: true);
  Get.put(PeopleDirectory(), permanent: true);
}
