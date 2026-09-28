import 'package:get/get.dart';

import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/core/utils/string_list.dart';

import '../../domain/models/project.dart';
import '../../domain/models/applicant.dart';
import '../../domain/project_failure.dart';
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
    fetchUserApplications();
    _seedActiveCollaborationDemo();
    _seedApplicantsDemo();
  }

  /// Carga desde Roble los proyectos creados por el usuario con la sesión activa.
  Future<void> fetchCoCreatedProjects() async {
    isLoadingProjects.value = true;
    try {
      final repository = Get.find<IProjectRepository>();
      final client = Get.isRegistered<RobleClient>()
          ? Get.find<RobleClient>()
          : null;

      if (client != null && client.db.isLoggedIn && !client.db.isAnonymous) {
        // `currentUserId` sale del token: es el `sub` y también el `_owner`
        // que el servidor escribe en cada fila.
        final String ownerId = client.currentUserId ?? '';
        final remoteProjects = await repository.getProjectsByOwner(ownerId);

        // Solo son "del usuario" los proyectos cuyo _owner coincide con la sesión activa.
        final ownerMatched = remoteProjects
            .where((p) => client.matchesUser(p.owner))
            .toList();

        // Registrar sus IDs para que isOwner() los reconozca sin tener que comparar el owner.
        for (final p in ownerMatched) {
          userCreatedProjectIds.add(p.id);
        }

        // Proyectos creados localmente en esta sesión que aún no estén en la respuesta remota.
        final remoteIds = ownerMatched.map((p) => p.id).toSet();
        final localOnly = coCreatedProjects
            .where(
              (p) =>
                  userCreatedProjectIds.contains(p.id) &&
                  !remoteIds.contains(p.id),
            )
            .toList();

        final combined = [...localOnly, ...ownerMatched];
        if (combined.isNotEmpty) {
          coCreatedProjects.assignAll(combined);
          await fetchJoinRequestsForCoCreatedProjects();
          return;
        }
      }
    } catch (_) {
      // Si ocurre error o no hay conexión, se conserva el estado actual.
    } finally {
      isLoadingProjects.value = false;
    }

    // Solo mostrar la semilla de demo si el usuario no tiene proyectos propios.
    final hasUserProjects = coCreatedProjects.any(
      (p) => userCreatedProjectIds.contains(p.id),
    );
    if (!hasUserProjects && coCreatedProjects.isEmpty) {
      _seedCoCreatedDemo();
    }
  }

  /// Determina si el usuario actual es el creador/propietario del proyecto.
  bool isOwner(Project project) {
    if (userCreatedProjectIds.contains(project.id)) return true;
    final client = Get.isRegistered<RobleClient>()
        ? Get.find<RobleClient>()
        : null;
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

      final createdProject = newProject.members.isEmpty
          ? newProject.copyWith(members: ['Tú (Creador)'])
          : newProject;

      coCreatedProjects.removeWhere(
        (p) => p.id == DummyData.kircheId || p.owner == 'demo-owner',
      );
      coCreatedProjects.insert(0, createdProject);
      return createdProject;
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
        bio: 'Especializada en análisis y minería de datos. Me gustan los proyectos con impacto real. He contribuido a dos startups universitarias como consultora.',
        skills: ['Python', 'Jupyter', 'PowerBI', 'SQL', 'R'],
        experience: [
          ApplicantProjectExperience(
            title: 'EcoMobility',
            status: 'Completado',
            description: 'Rediseñé la experiencia de usuario para una app de carpooling en Bogotá. Entregamos a tiempo y logramos un NPS de 72.',
            peerEvaluation: 4.2,
          ),
          ApplicantProjectExperience(
            title: 'Mercado Vivo',
            status: 'Incompleto',
            description: 'Proyecto interdisciplinario con estudiantes de Administración y Comunicación. Diseñé el sistema de identidad visual y los flujos de la plataforma.',
            peerEvaluation: 4.5,
          ),
        ],
      ),
    );
  }

  /// Carga las solicitudes de colaboración desde Roble DB para un proyecto específico.
  Future<void> fetchJoinRequestsForProject(String projectId) async {
    try {
      final repository = Get.find<IProjectRepository>();
      final requests = await repository.getJoinRequestsForProject(projectId);

      for (final req in requests) {
        // Solo mostrar solicitudes en estado 'pending'
        if (req.statusState.toLowerCase() != 'pending') {
          applicants.removeWhere((a) => a.id == req.id);
          continue;
        }

        // Cargar perfil del aspirante
        Map<String, dynamic>? profile;
        if (req.userId.isNotEmpty) {
          try {
            profile = await repository.getUserProfile(req.userId);
          } catch (_) {}
        }

        final applicantName = (profile?['name'] as String?)?.trim().isNotEmpty == true
            ? profile!['name'].toString().trim()
            : (req.userId.length > 8 ? 'Usuario ${req.userId.substring(0, 8)}' : 'Aspirante');

        final bio = (profile?['description'] as String?)?.trim().isNotEmpty == true
            ? profile!['description'].toString().trim()
            : 'Interesado en participar y colaborar activamente en este proyecto.';

        final skills = decodeStringList(profile?['skills']);

        final newApplicant = Applicant(
          id: req.id,
          projectId: req.projectId,
          userId: req.userId,
          name: applicantName,
          academicInfo: 'Estudiante / Colaborador',
          requestedRole: 'Colaborador',
          appliedAgo: _formatAgo(req.createdAt),
          commonProjects: 1,
          commitmentScore: 85,
          onTimeScore: 85,
          responseRateScore: 85,
          completedProjectsScore: 85,
          bio: bio,
          skills: skills.isNotEmpty ? skills : ['Trabajo en equipo', 'Compromiso'],
          experience: const [],
          statusState: req.statusState,
        );

        final existingIdx = applicants.indexWhere((a) => a.id == req.id);
        if (existingIdx != -1) {
          applicants[existingIdx] = newApplicant;
        } else {
          applicants.add(newApplicant);
        }
      }
    } catch (_) {}
  }

  /// Carga las solicitudes de colaboración para todos los proyectos co-creados.
  Future<void> fetchJoinRequestsForCoCreatedProjects() async {
    for (final p in coCreatedProjects) {
      await fetchJoinRequestsForProject(p.id);
    }
  }

  String _formatAgo(DateTime? date) {
    if (date == null) return 'Recientemente';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }

  List<Applicant> applicantsFor(String projectId) =>
      applicants.where((a) => a.projectId == projectId).toList();

  int pendingApplicantsCount(String projectId) =>
      applicantsFor(projectId).length;

  /// Acepta o rechaza la solicitud de un aspirante conectando con Roble DB (tabla `project_join_request`).
  /// Si es aceptada, inserta además la fila correspondiente en `project_member`.
  Future<bool> decideOnApplicant(Applicant applicant, {required bool accepted}) async {
    try {
      final repository = Get.find<IProjectRepository>();
      final client = Get.isRegistered<RobleClient>() ? Get.find<RobleClient>() : null;
      final reviewerId = client?.currentUserId ?? '';
      final newStatus = accepted ? 'accepted' : 'rejected';

      await repository.updateJoinRequestStatus(
        requestId: applicant.id,
        status: newStatus,
        reviewedBy: reviewerId,
      );

      if (accepted) {
        try {
          await repository.addProjectMember(
            projectId: applicant.projectId,
            userId: applicant.userId,
            role: {'name': applicant.requestedRole.isNotEmpty ? applicant.requestedRole : 'collaborator'},
          );
        } catch (_) {}

        final newMemberLabel = applicant.name.trim().isNotEmpty
            ? '${applicant.name.trim()} (${applicant.requestedRole})'
            : 'Colaborador (${applicant.requestedRole})';

        final idxCo = coCreatedProjects.indexWhere((p) => p.id == applicant.projectId);
        if (idxCo != -1) {
          final p = coCreatedProjects[idxCo];
          coCreatedProjects[idxCo] = p.copyWith(members: [...p.members, newMemberLabel]);
        }
        final idxAct = activeProjects.indexWhere((p) => p.id == applicant.projectId);
        if (idxAct != -1) {
          final p = activeProjects[idxAct];
          activeProjects[idxAct] = p.copyWith(members: [...p.members, newMemberLabel]);
        }
      }

      applicants.removeWhere((a) => a.id == applicant.id);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e is ProjectFailure ? e.message : 'No se pudo actualizar la solicitud.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
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

  /// Alterna el guardado de un proyecto. Retorna true si se guardó, false si se removió de guardados.
  bool toggleSaveProject(Project project) {
    if (isSaved(project.id)) {
      savedProjects.removeWhere((p) => p.id == project.id);
      return false;
    } else {
      savedProjects.add(project);
      return true;
    }
  }

  /// Carga desde Roble las postulaciones del usuario.
  /// Separa las postulaciones pendientes (se muestran en "Pendientes")
  /// de las aceptadas (se muestran en "Activos / Colaborando").
  Future<void> fetchUserApplications() async {
    try {
      final client = Get.isRegistered<RobleClient>() ? Get.find<RobleClient>() : null;
      final userId = client?.currentUserId ?? '';
      if (userId.isEmpty) return;

      final repository = Get.find<IProjectRepository>();
      final requests = await repository.getJoinRequestsByUser(userId);
      if (requests.isEmpty) return;

      final pendingIds = <String>{};
      final acceptedIds = <String>{};

      for (final req in requests) {
        final state = req.statusState.toLowerCase();
        if (state == 'accepted') {
          acceptedIds.add(req.projectId);
        } else if (state == 'pending') {
          pendingIds.add(req.projectId);
        }
      }

      appliedProjectIds.assignAll(pendingIds);

      // 1. Cargar proyectos aceptados en activeProjects (sección "Activos")
      for (final projectId in acceptedIds) {
        try {
          final project = await repository.getProjectById(projectId);
          if (project != null) {
            activeProjects.removeWhere((p) => p.owner == 'demo-owner' || p.id == DummyData.solariaId);
            if (!activeProjects.any((p) => p.id == project.id)) {
              activeProjects.add(project);
            }
          }
        } catch (_) {}
      }

      // 2. Cargar proyectos pendientes en savedProjects (sección "Pendientes")
      final alreadySaved = savedProjects.map((p) => p.id).toSet();
      final missingPendingIds = pendingIds.where((id) => !alreadySaved.contains(id)).toSet();

      for (final projectId in missingPendingIds) {
        try {
          final project = await repository.getProjectById(projectId);
          if (project != null && !savedProjects.any((p) => p.id == project.id)) {
            savedProjects.add(project);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Postula al usuario a un proyecto conectando con la BD Roble (tabla `project_join_request`).
  /// Retorna true si se postuló con éxito.
  Future<bool> applyToProject(Project project) async {
    saveProject(project);
    if (appliedProjectIds.contains(project.id)) {
      return false;
    }

    try {
      final repository = Get.find<IProjectRepository>();
      final client = Get.isRegistered<RobleClient>() ? Get.find<RobleClient>() : null;
      final userId = client?.currentUserId;

      await repository.createJoinRequest(
        projectId: project.id,
        userId: userId,
        status: 'pending',
      );
      appliedProjectIds.add(project.id);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error de postulación',
        e is ProjectFailure ? e.message : 'No se pudo registrar la solicitud en el servidor.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
