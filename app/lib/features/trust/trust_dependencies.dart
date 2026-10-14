import 'package:get/get.dart';

import '../../core/roble/roble_client.dart';
import '../../core/roble/roble_config.dart';
import 'data/datasources/i_trust_data_source.dart';
import 'data/datasources/in_memory_trust_data_source.dart';
import 'data/datasources/roble_trust_data_source.dart';
import 'data/repositories/trust_repository.dart';
import 'domain/repositories/i_trust_repository.dart';

void registerTrust({bool? useMock}) {
  final shouldUseMock = useMock ?? RobleConfig.contractId.isEmpty;

  Get.put<ITrustDataSource>(
    shouldUseMock
        ? InMemoryTrustDataSource()
        : RobleTrustDataSource(Get.find<RobleClient>()),
  );
  Get.put<ITrustRepository>(TrustRepository(Get.find<ITrustDataSource>()));
}
