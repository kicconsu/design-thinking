import 'package:get/get.dart';

import '../projects/domain/repositories/i_project_repository.dart';
import 'ui/viewmodels/discover_controller.dart';

void registerDiscover() {
  Get.lazyPut(() => DiscoverController(Get.find<IProjectRepository>()));
}
