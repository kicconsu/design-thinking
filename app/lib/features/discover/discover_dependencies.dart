import 'package:get/get.dart';

import '../../core/roble/roble_client.dart';
import '../../core/roble/roble_config.dart';
import 'data/datasources/i_project_data_source.dart';
import 'data/datasources/in_memory_project_data_source.dart';
import 'data/datasources/roble_project_data_source.dart';
import 'data/repositories/project_repository.dart';
import 'domain/repositories/i_project_repository.dart';
import 'ui/viewmodels/discover_controller.dart';

void registerDiscover({bool? useMock}) {
  final shouldUseMock = useMock ?? RobleConfig.contractId.isEmpty;

  if (shouldUseMock) {
    Get.put<IProjectDataSource>(InMemoryProjectDataSource());
  } else {
    Get.put<IProjectDataSource>(RobleProjectDataSource(Get.find<RobleClient>()));
  }

  Get.put<IProjectRepository>(ProjectRepository(Get.find<IProjectDataSource>()));
  Get.lazyPut(() => DiscoverController(Get.find<IProjectRepository>()));
}
