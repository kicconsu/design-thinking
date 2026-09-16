import 'package:get/get.dart';

import '../../../discover/domain/models/project.dart';

/// Mantiene el estado de los proyectos del usuario: los que co-crea,
/// los guardados, las postulaciones pendientes y las colaboraciones activas.
class UserProjectsController extends GetxController {
  final RxList<Project> coCreatedProjects = <Project>[].obs;
  final RxList<Project> savedProjects = <Project>[].obs;
  final RxSet<String> appliedProjectIds = <String>{}.obs;
  final RxList<Project> activeProjects = <Project>[].obs;

  // Índice de la pestaña principal (0: Co-creados, 1: Otros proyectos)
  final RxInt selectedMainTab = 0.obs;

  // Subcategoría actual de "Otros proyectos" (0: Guardados, 1: Pendientes, 2: Activos)
  final RxInt otherProjectsCategoryIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _seedCoCreatedDemo();
    _seedActiveCollaborationDemo();
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

  // Placeholder de proyecto en el que el usuario ya colabora activamente.
  void _seedActiveCollaborationDemo() {
    activeProjects.add(
      const Project(
        id: 'solaria-active',
        title: 'Solaria: Red comunitaria de microrredes solares',
        imageUrl: 'https://picsum.photos/seed/solaria-panel/800/450',
        jobs: ['Ing. Eléctrica', 'Desarrollador IoT'],
        skills: ['Hardware', 'Firmware', 'C++', 'Sistemas Embebidos'],
        description:
            'Implementación de microrredes solares conectadas entre vecinos para compartir excedentes de energía limpia.',
        members: ['Santiago Vargas', 'Tú (Colaborador)', 'Mariana Ruiz'],
        status: 'En Desarrollo',
        applicantsCount: 5,
      ),
    );
  }

  // Proyectos guardados que todavía no han sido postulados
  List<Project> get unappliedSavedProjects =>
      savedProjects.where((p) => !appliedProjectIds.contains(p.id)).toList();

  // Proyectos donde el usuario ya envió postulación y espera validación
  List<Project> get pendingProjects =>
      savedProjects.where((p) => appliedProjectIds.contains(p.id)).toList();

  // Proyectos donde el usuario ya trabaja activamente
  List<Project> get activeCollaborationProjects => activeProjects;

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
