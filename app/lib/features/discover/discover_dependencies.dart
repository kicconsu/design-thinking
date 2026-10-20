import 'package:get/get.dart';

import '../../core/roble/roble_client.dart';
import '../../core/roble/roble_config.dart';
import '../projects/domain/repositories/i_project_repository.dart';
import 'data/local_discover_repository.dart';
import 'data/roble_discover_repository.dart';
import 'domain/repositories/i_discover_repository.dart';
import 'ui/viewmodels/discover_controller.dart';

void registerDiscover({bool? useMock}) {
  // Una sola instancia durante toda la app: los filtros viven con la sesión y
  // se vacían en el cierre de sesión (`clear`).
  if (Get.isRegistered<DiscoverController>()) return;

  final shouldUseMock = useMock ?? RobleConfig.contractId.isEmpty;
  final IDiscoverRepository repository = shouldUseMock
      ? LocalDiscoverRepository(Get.find<IProjectRepository>())
      : RobleDiscoverRepository(Get.find<RobleClient>());

  Get.put(DiscoverController(repository), permanent: true);
}
