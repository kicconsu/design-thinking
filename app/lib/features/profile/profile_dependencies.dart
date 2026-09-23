import 'package:get/get.dart';

import '../../core/roble/roble_client.dart';
import '../../core/roble/roble_config.dart';
import 'data/datasources/i_profile_data_source.dart';
import 'data/datasources/in_memory_profile_data_source.dart';
import 'data/datasources/roble_profile_data_source.dart';
import 'data/repositories/profile_repository.dart';
import 'domain/repositories/i_profile_repository.dart';
import 'ui/viewmodels/profile_controller.dart';

void registerProfile({bool? useMock}) {
  final shouldUseMock = useMock ?? RobleConfig.contractId.isEmpty;

  if (shouldUseMock) {
    Get.put<IProfileDataSource>(InMemoryProfileDataSource());
  } else {
    Get.put<IProfileDataSource>(RobleProfileDataSource(Get.find<RobleClient>()));
  }

  Get.put<IProfileRepository>(ProfileRepository(Get.find<IProfileDataSource>()));
  Get.lazyPut(() => ProfileController(Get.find<IProfileRepository>()), fenix: true);
}
