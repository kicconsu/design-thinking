import 'package:get/get.dart';

import 'package:imker/features/auth/ui/pages/login_page.dart';
import 'package:imker/features/auth/ui/pages/register_page.dart';
import 'package:imker/features/auth/ui/pages/upgrade_account_page.dart';
import 'package:imker/features/discover/discover_dependencies.dart';
import 'package:imker/features/home/ui/pages/home_page.dart';
import 'package:imker/features/home/ui/pages/splash_page.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/features/projects/ui/pages/project_detail_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/routes/app_routes.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Registra una instancia recién creada, descartando la que hubiera.
///
/// Necesario para pantallas con argumento de ruta: [Get.put] conserva la
/// instancia existente, así que volver a abrir la pantalla seguiría mostrando
/// el argumento anterior.
// ignore: unused_element
void _putFresh<T>(T instance) {
  if (Get.isRegistered<T>()) Get.delete<T>(force: true);
  Get.put<T>(instance);
}

// ─── Bindings ─────────────────────────────────────────────────────────────────

/// Las pestañas del IndexedStack viven todas a la vez, así que sus ViewModels
/// se registran con `fenix: true` para que sobrevivan a cualquier [Get.delete]
/// y se reconstruyan solos al volver.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeViewModel(), fenix: true);
    Get.lazyPut(() => UserProjectsController(), fenix: true);
    registerDiscover();
  }
}

/// El detalle de proyecto depende del argumento de la ruta: instancia nueva en
/// cada entrada para que no reutilice el contexto del proyecto anterior.
class ProjectDetailBinding extends Bindings {
  @override
  void dependencies() {
    // El ProjectDetailPage recibe el projectId de Get.arguments;
    // cuando exista un ProjectDetailViewModel se registrará aquí con _putFresh.
    // Por ahora el Binding existe para anclar el patrón sin lógica extra.
  }
}

// ─── Tabla de rutas ───────────────────────────────────────────────────────────

abstract class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(name: AppRoutes.register, page: () => const RegisterPage()),
    GetPage(
      name: AppRoutes.upgradeAccount,
      page: () => const UpgradeAccountPage(),
    ),
    GetPage(
      name: AppRoutes.projectDetail,
      page: () => const ProjectDetailPage(),
      binding: ProjectDetailBinding(),
    ),
  ];
}
