import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'core/preferences/i_local_preferences.dart';
import 'core/preferences/local_preferences_secured.dart';
import 'core/preferences/local_preferences_shared.dart';
import 'core/roble/roble_client.dart';
import 'core/roble/roble_config.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_builder.dart';
import 'features/auth/auth_dependencies.dart';
import 'features/projects/projects_dependencies.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Loggy.initLoggy(logPrinter: const PrettyPrinter(showColors: true));

  final ILocalPreferences preferences = kIsWeb
      ? LocalPreferencesShared()
      : LocalPreferencesSecured();
  Get.put<ILocalPreferences>(preferences, permanent: true);

  // Cliente de Roble con timeout de 10s para evitar bloqueos si el servidor se satura
  if (RobleConfig.contractId.isNotEmpty) {
    final robleClient = RobleClient(
      baseUrl: RobleConfig.baseUrl,
      contractId: RobleConfig.contractId,
      timeout: const Duration(seconds: 10),
    );
    Get.put(robleClient, permanent: true);
  }

  // Infraestructura permanente
  registerAuth();
  registerProjects();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, 'Inter', 'DM Serif Display');
    MaterialTheme theme = MaterialTheme(textTheme);

    return GetMaterialApp(
      title: 'Imker',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
