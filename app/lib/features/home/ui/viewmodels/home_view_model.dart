import 'package:get/get.dart';

import 'package:imker/routes/app_routes.dart';

class HomeViewModel extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }

  /// Para la barra de navegación de las páginas apiladas encima de Home
  /// (información de proyecto, gabinete, progreso de tarea…): cierra esas
  /// páginas hasta volver a Home y lo deja en la pestaña [index].
  void openTab(int index) {
    changePage(index);
    Get.until((route) => route.settings.name == AppRoutes.home);
  }
}
