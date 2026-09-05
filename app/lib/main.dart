import 'package:f_clean_template/core/theme.dart';
import 'package:f_clean_template/core/theme_builder.dart';
import 'package:f_clean_template/features/scroll/ui/view/scrollpage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'core/i_local_preferences.dart';
import 'core/local_preferences_secured.dart';
import 'core/local_preferences_shared.dart';

import 'features/auth/auth_dependencies.dart';
import 'features/product/product_dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Loggy.initLoggy(logPrinter: const PrettyPrinter(showColors: true));

  final ILocalPreferences preferences = kIsWeb
      ? LocalPreferencesShared()
      : LocalPreferencesSecured();
  Get.put<ILocalPreferences>(preferences, permanent: true);

  registerAuth();
  registerProduct();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Inter", "DM Serif Display");
    MaterialTheme theme = MaterialTheme(textTheme);
    return GetMaterialApp(
      title: 'Imker',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      debugShowCheckedModeBanner: false,
      home: const ScrollPage(),
    );
  }
}
