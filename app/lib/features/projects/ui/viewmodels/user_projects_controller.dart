import 'package:get/get.dart';

import '../../../discover/domain/models/project.dart';

/// Mantiene el estado de los proyectos del usuario: los que guardó desde
/// Descubrir ("Estoy interesado!") y los que co-crea. No hay backend todavía,
/// así que todo vive en memoria mientras dure la sesión.
class UserProjectsController extends GetxController {
  final RxList<Project> coCreatedProjects = <Project>[].obs;
  final RxList<Project> savedProjects = <Project>[].obs;
  final RxSet<String> appliedProjectIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _seedCoCreatedDemo();
  }

  // Placeholder mientras no exista el flujo real de creación de proyectos.
  void _seedCoCreatedDemo() {
    coCreatedProjects.add(
      const Project(
        id: 'kirche-co-created',
        title: 'Kirche: Proyecto de renovación urbana y sostenibilidad',
        imageUrl:
            'https://fultoncountyvetclinic.com/wp-content/uploads/bb-plugin/cache/cat-stretching-panorama-fd4135722bc818a9db1debc7def411a0-4hg3jvxm67az.jpg',
        jobs: ['Ing. Software', 'Ing. Ambiental', 'Ing. Electrónica', 'Ing. Industrial'],
        skills: ['Modelación', 'Análisis de datos', 'Desarrollo de software', 'Diseño de software'],
        description:
            'Proyecto de renovación urbana enfocado en la integración de tecnologías sostenibles en edificios históricos.',
        members: ['Pedro Jiménez', 'Alberto Mendoza', 'Juana De Arco'],
        status: 'Activo',
        applicantsCount: 3,
      ),
    );
  }

  bool isSaved(String projectId) =>
      savedProjects.any((project) => project.id == projectId);

  bool isApplied(String projectId) => appliedProjectIds.contains(projectId);

  void saveProject(Project project) {
    if (!isSaved(project.id)) {
      savedProjects.add(project);
    }
  }

  void applyToProject(Project project) {
    saveProject(project);
    appliedProjectIds.add(project.id);
  }
}
