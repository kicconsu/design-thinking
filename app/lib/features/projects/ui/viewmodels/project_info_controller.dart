import 'package:get/get.dart';

import '../../domain/models/project.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import 'user_projects_controller.dart';

/// Estado de la vista de información de un proyecto (pestañas Progreso,
/// Info. básica y Miembros). Una instancia por proyecto abierto.
class ProjectInfoController extends GetxController {
  ProjectInfoController(Project initial) : project = initial.obs;

  /// El proyecto tal como se ve ahora: arranca con lo que traía la lista y se
  /// reemplaza por la lectura fresca de [reload].
  final Rx<Project> project;

  final RxBool isRefreshing = false.obs;

  @override
  void onReady() {
    super.onReady();
    // La lista pudo cargarse antes de que alguien cambiara una tarea.
    reload();
  }

  /// Vuelve a leer el proyecto (su `progress` lo mantiene el repositorio de
  /// tareas) y propaga el resultado a las listas de "Mis proyectos" y
  /// "Activos" para que no queden con el valor viejo.
  Future<void> reload() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      final fresh = await Get.find<IProjectRepository>().getProjectById(
        project.value.id,
      );
      if (fresh == null) return;
      project.value = fresh;
      if (Get.isRegistered<UserProjectsController>()) {
        Get.find<UserProjectsController>().replaceProject(fresh);
      }
    } on ProjectFailure {
      // Sin red se conserva lo que ya estaba en pantalla.
    } finally {
      isRefreshing.value = false;
    }
  }
}
