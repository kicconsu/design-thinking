import 'package:get/get.dart';

import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/core/data/dummy_data.dart';
import '../../domain/models/project.dart';
import '../../domain/models/applicant.dart';
import '../../domain/repositories/i_project_repository.dart';


/// Mantiene el estado de los proyectos del usuario: los que co-crea,
/// los guardados, las postulaciones pendientes y las colaboraciones activas.
class UserProjectsController extends GetxController {
  final RxList<Project> coCreatedProjects = <Project>[].obs;
  final RxList<Project> savedProjects = <Project>[].obs;
  final RxSet<String> appliedProjectIds = <String>{}.obs;
  final RxList<Project> activeProjects = <Project>[].obs;

  /// IDs de proyectos explícitamente creados por el usuario activo.
  final RxSet<String> userCreatedProjectIds = <String>{}.obs;

  final RxBool isCreating = false.obs;
  final RxBool isLoadingProjects = false.obs;

  // Índice de la pestaña principal (0: Co-creados, 1: Otros proyectos)
  final RxInt selectedMainTab = 0.obs;

  // Subcategoría actual de "Otros proyectos" (0: Guardados, 1: Pendientes, 2: Activos)
  final RxInt otherProjectsCategoryIndex = 0.obs;
  final RxList<Applicant> applicants = <Applicant>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCoCreatedProjects();
    _seedActiveCollaborationDemo();
    _seedApplicantsDemo();
  }

  /// Carga desde Roble los proyectos creados por el usuario con la sesión activa.
  Future<void> fetchCoCreatedProjects() async {
    isLoadingProjects.value = true;
    try {
      final repository = Get.find<IProjectRepository>();
      final client = Get.isRegistered<RobleClient>() ? Get.find<RobleClient>() : null;

      if (client != null && client.db.isLoggedIn && !client.db.isAnonymous) {
        // Refrescar SIEMPRE el perfil para tener todos los identificadores actualizados.
        try {
          final profile = await client.db.currentUser();
          client.currentUserIdentifiers.clear();
          // Poblar con TODOS los valores del perfil para maximizar las coincidencias.
          for (final val in profile.values) {
            final str = val?.toString().trim();
            if (str != null && str.isNotEmpty) {
              client.currentUserIdentifiers.add(str);
            }
          }
          client.currentUserId = (profile['user_id'] ??
                  profile['_owner'] ??
                  profile['id'] ??
                  profile['_id'])
              ?.toString();
          client.currentUserEmail = profile['email']?.toString();
        } catch (_) {}

        final String ownerId = client.currentUserId ?? '';
        final remoteProjects = await repository.getProjectsByOwner(ownerId);

        // Solo son "del usuario" los proyectos cuyo _owner coincide con la sesión activa.
        final ownerMatched = remoteProjects.where((p) => client.matchesUser(p.owner)).toList();

        // Registrar sus IDs para que isOwner() los reconozca sin tener que comparar el owner.
        for (final p in ownerMatched) {
          userCreatedProjectIds.add(p.id);
        }

        // Proyectos creados localmente en esta sesión que aún no estén en la respuesta remota.
        final remoteIds = ownerMatched.map((p) => p.id).toSet();
        final localOnly = coCreatedProjects
            .where((p) => userCreatedProjectIds.contains(p.id) && !remoteIds.contains(p.id))
            .toList();

        final combined = [...localOnly, ...ownerMatched];
        if (combined.isNotEmpty) {
          coCreatedProjects.assignAll(combined);
          return;
        }
      }
    } catch (_) {
      // Si ocurre error o no hay conexión, se conserva el estado actual.
    } finally {
      isLoadingProjects.value = false;
    }

    // Solo mostrar la semilla de demo si el usuario no tiene proyectos propios.
    final hasUserProjects = coCreatedProjects.any((p) => userCreatedProjectIds.contains(p.id));
    if (!hasUserProjects && coCreatedProjects.isEmpty) {
      _seedCoCreatedDemo();
    }
  }

  /// Determina si el usuario actual es el creador/propietario del proyecto.
  bool isOwner(Project project) {
    if (userCreatedProjectIds.contains(project.id)) return true;
    final client = Get.isRegistered<RobleClient>() ? Get.find<RobleClient>() : null;
    if (client != null && client.db.isLoggedIn && !client.db.isAnonymous) {
      return client.matchesUser(project.owner);
    }
    return false;
  }




  /// Crea un nuevo proyecto en Roble / repositorio y lo agrega a [coCreatedProjects].
  Future<Project> createProject({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
    String imageUrl = '',
  }) async {
    try {
      isCreating.value = true;
      final repository = Get.find<IProjectRepository>();
      final newProject = await repository.createProject(
        title: title,
        description: description,
        jobs: jobs,
        skills: skills,
        imageUrl: imageUrl,
      );
      userCreatedProjectIds.add(newProject.id);

      coCreatedProjects.removeWhere(
        (p) => p.id == DummyData.kircheId || p.owner == 'demo-owner',
      );
      coCreatedProjects.insert(0, newProject);
      return newProject;
    } finally {
      isCreating.value = false;
    }
  }

  // Placeholder mientras no exista el flujo real de creación de proyectos.
  void _seedCoCreatedDemo() {
    coCreatedProjects.add(DummyData.kircheProject);
  }


  // Placeholder de proyecto en el que el usuario ya colabora activamente.
  void _seedActiveCollaborationDemo() {
    activeProjects.add(DummyData.solariaProject);
  }

  // Proyectos guardados que todavía no han sido postulados
  List<Project> get unappliedSavedProjects =>
      savedProjects.where((p) => !appliedProjectIds.contains(p.id)).toList();

  // Proyectos donde el usuario ya envió postulación y espera validación
  List<Project> get pendingProjects =>
      savedProjects.where((p) => appliedProjectIds.contains(p.id)).toList();

  // Proyectos donde el usuario ya trabaja activamente
  List<Project> get activeCollaborationProjects => activeProjects;

  // Placeholder mientras no exista el flujo real de postulación con backend.
  void _seedApplicantsDemo() {
    applicants.add(
      const Applicant(
        id: 'valentina-rios',
        projectId: DummyData.kircheId,
        name: 'Valentina Ríos',
        academicInfo: 'Ingeniería de Sistemas - Universidad de la Costa',
        requestedRole: 'Analista de datos',
        appliedAgo: 'hace 5h',
        commonProjects: 1,
        commitmentScore: 83,
        onTimeScore: 83,
        responseRateScore: 83,
        completedProjectsScore: 83,
        bio:
            'Especializada en análisis y minería de datos. Me gustan los proyectos con impacto real. He contribuido a dos startups universitarias como consultora.',
        skills: ['Python', 'Jupyter', 'PowerBI', 'SQL', 'R'],
        experience: [
          ApplicantProjectExperience(
            title: 'EcoMobility',
            status: 'Completado',
            description:
                'Rediseñé la experiencia de usuario para una app de carpooling en Bogotá. Entregamos a tiempo y logramos un NPS de 72.',
            peerEvaluation: 4.2,
          ),
          ApplicantProjectExperience(
            title: 'Mercado Vivo',
            status: 'Incompleto',
            description:
                'Proyecto interdisciplinario con estudiantes de Administración y Comunicación. Diseñé el sistema de identidad visual y los flujos de la plataforma.',
            peerEvaluation: 4.5,
          ),
        ],
      ),
    );
  }

  List<Applicant> applicantsFor(String projectId) =>
      applicants.where((a) => a.projectId == projectId).toList();

  int pendingApplicantsCount(String projectId) =>
      applicantsFor(projectId).length;

  void decideOnApplicant(Applicant applicant, {required bool accepted}) {
    applicants.removeWhere((a) => a.id == applicant.id);
  }

  bool isSaved(String projectId) =>
      savedProjects.any((project) => project.id == projectId);

  bool isApplied(String projectId) => appliedProjectIds.contains(projectId);

  /// Guarda un proyecto. Retorna true si se guardó con éxito, false si ya estaba guardado o no se pudo.
  bool saveProject(Project project) {
    if (!isSaved(project.id)) {
      savedProjects.add(project);
      return true;
    }
    return false;
  }

  /// Postula al usuario a un proyecto. Retorna true si se postuló con éxito.
  bool applyToProject(Project project) {
    saveProject(project);
    if (!appliedProjectIds.contains(project.id)) {
      appliedProjectIds.add(project.id);
      return true;
    }
    return false;
  }
}
