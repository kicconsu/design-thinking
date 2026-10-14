import 'package:get/get.dart';

import '../../core/roble/roble_client.dart';
import '../../core/roble/roble_config.dart';
import 'data/datasources/i_task_data_source.dart';
import 'data/datasources/in_memory_task_data_source.dart';
import 'data/datasources/roble_task_data_source.dart';
import 'data/repositories/task_repository.dart';
import 'domain/repositories/i_task_repository.dart';

void registerTasks({bool? useMock}) {
  final shouldUseMock = useMock ?? RobleConfig.contractId.isEmpty;

  Get.put<ITaskDataSource>(
    shouldUseMock
        ? InMemoryTaskDataSource()
        : RobleTaskDataSource(Get.find<RobleClient>()),
  );
  Get.put<ITaskRepository>(TaskRepository(Get.find<ITaskDataSource>()));
}
