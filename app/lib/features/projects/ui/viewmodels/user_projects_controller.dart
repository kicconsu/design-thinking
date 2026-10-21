import 'package:get/get.dart';

import 'package:imker/core/roble/roble_client.dart';
import 'package:imker/core/roble/roble_config.dart';

import '../../domain/models/project.dart';
import '../../domain/models/project_relation.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import 'collaboration_requests_controller.dart';
import 'invitations_controller.dart';

/// Mantiene el estado de los proyectos del usuario: los que co-crea,
/// los guardados, las postulaciones pendientes y las colaboraciones activas.
class UserProjectsController extends GetxController {
  /// [currentUserId] sustituye a la sesión real: solo para pruebas.
  UserProjectsController({String Function()? currentUserId})
    : _userIdOverride = currentUserId;

  final String Function()? _userIdOverride;

  final RxList<Project> coCreatedProjects = <Project>[].obs;
  final RxList<Project> savedProjects = <Project>[].obs;
  final RxSet<String> appliedProjectIds = <String>{}.obs;
  final RxList<Project> activeProjects = <Project>[].obs;

  /// IDs de proyectos explícitamente creados por el usuario activo.
  final RxSet<String> userCreatedProjectIds = <String>{}.obs;

  final RxBool isCreating = false.obs;
  final RxBool isLoadingProjects = false.obs;

  // Índice de la pestaña principal (0: Mis proyectos, 1: Otros proyectos)
  final RxInt selectedMainTab = 0.obs;

  // Subcategoría actual de "Otros proyectos" (0: Guardados, 1: Pendientes, 2: Activos)
  final RxInt otherProjectsCategoryIndex = 0.obs;

  // Una sola instancia para toda la app. Quien entra o sale de sesión la
  // llena con [AuthenticationController] y la vacía con [clear].

  /// Olvida todo lo de la sesión que se va: la siguiente persona no debe ver
  /// ni una lista suya. Las cargas que sigan en vuelo se descartan solas
  /// (ver [_inSession]).
  void clear() {
    coCreatedProjects.clear();
    savedProjects.clear();
    appliedProjectIds.clear();
    activeProjects.clear();
    userCreatedProjectIds.clear();
    selectedMainTab.value = 0;
    otherProjectsCategoryIndex.value = 0;
    isLoadingProjects.value = false;
  }

  /// ¿Sigue activa la sesión de [userId]? Una carga que empezó con otra
  /// persona y termina después del cambio no debe escribir en las listas.
  bool _inSession(String userId) => _currentUserId == userId;

  /// ¿Hay dónde persistir los guardados? Sin contrato (modo mock) se guarda
  /// en el datasource en memoria; con contrato hace falta una sesión real,
  /// porque el invitado no tiene permiso de escritura sobre sus filas.
  bool get _canPersistSaved {
    if (RobleConfig.contractId.isEmpty) return true;
    final client = Get.isRegistered<RobleClient>()
        ? Get.find<RobleClient>()
        : null;
    if (client == null) return false;
    return client.db.isLoggedIn && !client.db.isAnonymous;
  }

  String get _currentUserId {
    if (_userIdOverride != null) return _userIdOverride();
    final client = Get.isRegistered<RobleClient>()
        ? Get.find<RobleClient>()
        : null;
    if (client == null) return '';
    if (RobleConfig.contractId.isEmpty) return 'demo-user';
    return client.currentUserId ?? '';
  }

  /// Hidrata [savedProjects] desde `project_saved` al abrir la app.
  /// Los proyectos de las postulaciones pendientes ya los carga
  /// [fetchUserApplications], aquí sólo entran los guardados a mano.
  Future<void> fetchSavedProjects() async {
    if (!_canPersistSaved) return;
    final userId = _currentUserId;
    if (userId.isEmpty) return;
    try {
      final repository = Get.find<IProjectRepository>();
      final ids = await repository.getSavedProjectIds(userId);
      if (!_inSession(userId)) return;
      for (final id in ids) {
        if (savedProjects.any((p) => p.id == id)) continue;
        final project = await repository.getProjectById(id);
        if (!_inSession(userId)) return;
        if (project != null && !savedProjects.any((p) => p.id == project.id)) {
          savedProjects.add(project);
        }
      }
    } catch (_) {
      // Sin conexión se conserva lo que ya estuviera en memoria.
    }
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
        if (!_inSession(ownerId)) return;

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
          if (Get.isRegistered<CollaborationRequestsController>()) {
            await Get.find<CollaborationRequestsController>().fetchForProjects(
              combined.map((p) => p.id),
            );
          }
          return;
        }
      }
    } catch (_) {
      // Si ocurre error o no hay conexión, se conserva el estado actual.
    } finally {
      isLoadingProjects.value = false;
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
  ///
  /// [inviteEmails] se verifica TODOS antes de escribir nada: si alguno no
  /// tiene cuenta, lanza [ProjectFailure] y no se crea el proyecto.
  Future<Project> createProject({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
    String imageUrl = '',
    List<String> inviteEmails = const [],
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
        inviteEmails: inviteEmails,
      );
      userCreatedProjectIds.add(newProject.id);

      coCreatedProjects.insert(0, newProject);
      return newProject;
    } finally {
      isCreating.value = false;
    }
  }

  /// Cómo se relaciona la sesión con [project], con una sola respuesta:
  /// owner > active > invited > pending > saved > none. Todas las pantallas
  /// preguntan aquí en vez de combinar guardados, postulaciones y membresías.
  ProjectRelation relationOf(Project project) {
    if (isOwner(project)) return ProjectRelation.owner;
    if (activeProjects.any((p) => p.id == project.id)) {
      return ProjectRelation.active;
    }
    if (_isInvited(project.id)) return ProjectRelation.invited;
    if (appliedProjectIds.contains(project.id)) return ProjectRelation.pending;
    if (isSaved(project.id)) return ProjectRelation.saved;
    return ProjectRelation.none;
  }

  bool _isInvited(String projectId) =>
      Get.isRegistered<InvitationsController>() &&
      Get.find<InvitationsController>().invitations.any(
        (i) => i.projectId == projectId,
      );

  // Guardados: solo lo guardado y nada más (ni activo, ni invitado, ni
  // postulado). Un guardado es una preferencia, no un historial.
  List<Project> get unappliedSavedProjects => savedProjects
      .where((p) => relationOf(p) == ProjectRelation.saved)
      .toList();

  // Pendientes: postulé y espero la decisión. Los pendientes viven en
  // [savedProjects] para poder pintarse.
  List<Project> get pendingProjects => savedProjects
      .where((p) => relationOf(p) == ProjectRelation.pending)
      .toList();

  // Proyectos donde el usuario ya trabaja activamente
  List<Project> get activeCollaborationProjects => activeProjects;

  /// Vuelve a leer un proyecto (p. ej. tras aceptar a alguien) y actualiza
  /// las listas donde aparece.
  Future<void> refreshProject(String projectId) async {
    try {
      final fresh = await Get.find<IProjectRepository>().getProjectById(
        projectId,
      );
      if (fresh == null) return;
      replaceProject(fresh);
    } on ProjectFailure {
      // Se conserva lo que ya estuviera en pantalla.
    }
  }

  /// Sustituye [fresh] en las listas donde ya aparece el proyecto.
  void replaceProject(Project fresh) {
    for (final list in [coCreatedProjects, activeProjects]) {
      final i = list.indexWhere((p) => p.id == fresh.id);
      if (i != -1) list[i] = fresh;
    }
  }

  /// Añade un proyecto a "Activos" (p. ej. tras aceptar una invitación).
  void addActiveProject(Project project) {
    _manualActiveAdds++;
    _putActive(project);
  }

  /// La persona salió del proyecto: deja de ser activo y de estar guardado
  /// (salir borra también el guardado en el servidor).
  void leftProject(String projectId) {
    activeProjects.removeWhere((p) => p.id == projectId);
    savedProjects.removeWhere((p) => p.id == projectId);
    appliedProjectIds.remove(projectId);
  }

  /// Altas hechas a mano desde la app (no leídas del servidor). Una recarga
  /// que empezó antes de una de ellas no puede podar la lista.
  int _manualActiveAdds = 0;

  void _putActive(Project project) {
    // Ya colabora: una postulación pendiente a este proyecto quedó obsoleta.
    appliedProjectIds.remove(project.id);
    if (activeProjects.any((p) => p.id == project.id)) return;
    activeProjects.add(project);
  }

  bool isSaved(String projectId) =>
      savedProjects.any((project) => project.id == projectId);

  bool isApplied(String projectId) => appliedProjectIds.contains(projectId);

  /// Guarda un proyecto en memoria. Sólo lo usa el flujo de postulación;
  /// para alternar desde la pantalla hay que usar [toggleSaveProject].
  bool saveProject(Project project) {
    if (!isSaved(project.id)) {
      savedProjects.add(project);
      return true;
    }
    return false;
  }

  /// Escribe o borra la fila en `project_saved`. Si no hay dónde persistir
  /// (invitado, modo mock sin contrato) se comporta como sólo local.
  Future<void> _persistSaved(Project project, {required bool saving}) async {
    if (!_canPersistSaved) return;
    final repository = Get.find<IProjectRepository>();
    final userId = _currentUserId;
    if (saving) {
      await repository.saveProject(userId: userId, projectId: project.id);
    } else {
      await repository.unsaveProject(userId: userId, projectId: project.id);
    }
  }

  /// Alterna el guardado de un proyecto y lo persiste en `project_saved`.
  /// Retorna true si quedó guardado, false si se quitó de guardados.
  ///
  /// Si el servidor rechaza la operación se deshace el cambio optimista:
  /// lo que se ve en pantalla siempre es lo que está guardado de verdad.
  ///
  /// No opera sobre proyectos con postulación pendiente (ni para guardar ni
  /// para desguardar): ahí el estado lo manda [appliedProjectIds] y la pestaña
  /// "Pendientes" se calcula como guardados ∩ aplicados, así que sacarlos de
  /// [savedProjects] los haría desaparecer de ahí.
  Future<bool> toggleSaveProject(Project project) async {
    if (isApplied(project.id)) return isSaved(project.id);

    final wasSaved = isSaved(project.id);
    if (wasSaved) {
      savedProjects.removeWhere((p) => p.id == project.id);
    } else {
      savedProjects.add(project);
    }

    try {
      await _persistSaved(project, saving: !wasSaved);
    } catch (e) {
      if (wasSaved) {
        savedProjects.add(project);
      } else {
        savedProjects.removeWhere((p) => p.id == project.id);
      }
      Get.snackbar(
        'No se pudo actualizar',
        e is ProjectFailure
            ? e.message
            : 'No se pudo guardar el proyecto. Intenta de nuevo.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return wasSaved;
    }
    return !wasSaved;
  }

  /// Carga desde Roble las postulaciones del usuario.
  /// Separa las postulaciones pendientes (se muestran en "Pendientes")
  /// de las aceptadas (se muestran en "Activos / Colaborando").
  Future<void> fetchUserApplications() async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) return;

      final repository = Get.find<IProjectRepository>();
      final requests = await repository.getJoinRequestsByUser(userId);
      if (!_inSession(userId)) return;

      // Activos sale SOLO de la membresía. Las solicitudes y las invitaciones
      // `accepted` son historia: lo que dice si colaboro hoy es mi fila activa
      // de `project_member` (así, si me echan o salgo, dejo de ser activo).
      final pendingIds = <String>{};
      final memberIds = <String>{};
      var membersLoaded = false;
      final manualAddsAtStart = _manualActiveAdds;
      try {
        memberIds.addAll(await repository.getMemberProjectIds(userId));
        membersLoaded = true;
      } on ProjectFailure {
        // Sin membresías no se toca lo que ya hubiera en Activos.
      }
      if (!_inSession(userId)) return;

      for (final req in requests) {
        if (req.statusState.toLowerCase() == 'pending') {
          pendingIds.add(req.projectId);
        }
      }

      // Si ya es miembro (p. ej. por una invitación), la solicitud pendiente
      // al mismo proyecto no cuenta.
      pendingIds.removeAll(memberIds);
      appliedProjectIds.assignAll(pendingIds);

      // 1. Cargar los proyectos donde colaboro (sección "Activos").
      for (final projectId in memberIds) {
        try {
          final project = await repository.getProjectById(projectId);
          if (!_inSession(userId)) return;
          if (project != null) _putActive(project);
        } catch (_) {}
      }

      // Los que dejaron de ser mis proyectos activos salen. Solo si la lectura
      // fue completa y nadie añadió uno a mano mientras tanto.
      if (membersLoaded && manualAddsAtStart == _manualActiveAdds) {
        activeProjects.removeWhere((p) => !memberIds.contains(p.id));
      }

      // 2. Cargar proyectos pendientes en savedProjects (sección "Pendientes")
      final alreadySaved = savedProjects.map((p) => p.id).toSet();
      final missingPendingIds = pendingIds
          .where((id) => !alreadySaved.contains(id))
          .toSet();

      for (final projectId in missingPendingIds) {
        try {
          final project = await repository.getProjectById(projectId);
          if (!_inSession(userId)) return;
          if (project != null &&
              !savedProjects.any((p) => p.id == project.id)) {
            savedProjects.add(project);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Postula al usuario a un proyecto conectando con la BD Roble (tabla `project_join_request`).
  /// Retorna true si se postuló con éxito.
  Future<bool> applyToProject(Project project) async {
    if (appliedProjectIds.contains(project.id)) return false;

    try {
      final repository = Get.find<IProjectRepository>();
      final client = Get.isRegistered<RobleClient>()
          ? Get.find<RobleClient>()
          : null;
      final userId = client?.currentUserId;

      // El repositorio rechaza si ya colaboro, ya postulé o ya me invitaron.
      await repository.createJoinRequest(
        projectId: project.id,
        userId: userId,
        status: 'pending',
      );
      appliedProjectIds.add(project.id);
    } catch (e) {
      Get.snackbar(
        'Error de postulación',
        e is ProjectFailure
            ? e.message
            : 'No se pudo registrar la solicitud en el servidor.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Queda guardado para que aparezca en Pendientes; si el servidor no lo
    // acepta, se sigue guardando en memoria.
    final alreadySaved = isSaved(project.id);
    saveProject(project);
    if (!alreadySaved) {
      try {
        await _persistSaved(project, saving: true);
      } catch (_) {}
    }
    return true;
  }
}
