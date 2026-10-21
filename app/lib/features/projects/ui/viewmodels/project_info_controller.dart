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
  final RxBool isClosing = false.obs;

  @override
  void onReady() {
    super.onReady();
    // La lista pudo cargarse antes de que alguien cambiara una tarea.
    reload();
  }

  /// Cierra el proyecto: deja de recibir solicitudes e invitaciones. Quién
  /// puede pedirlo (el creador) lo decide la pantalla. Devuelve null si salió
  /// bien o el mensaje de error para mostrar.
  Future<String?> closeProject() async {
    if (!project.value.isOpen) return null;
    if (isClosing.value) return null;
    isClosing.value = true;
    try {
      applyProject(
        await Get.find<IProjectRepository>().closeProject(project.value.id),
      );
      return null;
    } on ProjectFailure catch (e) {
      return e.message;
    } finally {
      isClosing.value = false;
    }
  }

  /// Deja [fresh] como el proyecto que se ve y lo propaga a las listas de
  /// "Mis proyectos" y "Activos".
  void applyProject(Project fresh) {
    project.value = fresh;
    if (Get.isRegistered<UserProjectsController>()) {
      Get.find<UserProjectsController>().replaceProject(fresh);
    }
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
      applyProject(fresh);
    } on ProjectFailure {
      // Sin red se conserva lo que ya estaba en pantalla.
    } finally {
      isRefreshing.value = false;
    }
  }
}
