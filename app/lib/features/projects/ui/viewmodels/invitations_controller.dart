import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';

import '../../domain/models/project.dart';
import '../../domain/models/project_invitation.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import 'user_projects_controller.dart';

/// Invitaciones a proyectos que recibió el usuario y su respuesta.
class InvitationsController extends GetxController {
  InvitationsController({
    IProjectRepository? repository,
    String Function()? currentUserId,
    void Function(Project)? onAccepted,
  }) : _repository = repository ?? Get.find<IProjectRepository>(),
       _currentUserId =
           currentUserId ??
           (() => Get.find<AuthenticationController>().loggedUserId),
       _onAccepted =
           onAccepted ??
           ((p) {
             if (Get.isRegistered<UserProjectsController>()) {
               Get.find<UserProjectsController>().addActiveProject(p);
             }
           });

  final IProjectRepository _repository;
  final String Function() _currentUserId;
  final void Function(Project) _onAccepted;

  final RxList<ProjectInvitation> invitations = <ProjectInvitation>[].obs;

  /// Proyecto de cada invitación, para mostrar su título.
  final RxMap<String, Project> projects = <String, Project>{}.obs;

  final RxBool isLoading = false.obs;

  /// Sube con cada [clear]: una carga que empezó antes de salir de sesión no
  /// debe escribir lo suyo en la lista de quien entre después.
  int _epoch = 0;

  /// Olvida las invitaciones de la sesión que se va.
  void clear() {
    _epoch++;
    invitations.clear();
    projects.clear();
    isLoading.value = false;
  }

  /// Lee las invitaciones pendientes. Una invitación a un proyecto que ya no
  /// existe (p. ej. una creación deshecha) no se muestra.
  Future<void> fetch() async {
    final userId = _currentUserId();
    if (userId.isEmpty) {
      invitations.clear();
      return;
    }
    final epoch = _epoch;
    try {
      isLoading.value = true;
      final pending = await _repository.getPendingInvitations(userId);
      // Una invitación a un proyecto donde ya colaboro (p. ej. me aceptaron
      // una solicitud) no tiene nada que responder.
      final memberOf = (await _repository.getMemberProjectIds(userId)).toSet();
      final shown = <ProjectInvitation>[];
      for (final inv in pending) {
        if (memberOf.contains(inv.projectId)) continue;
        final project =
            projects[inv.projectId] ??
            await _repository.getProjectById(inv.projectId);
        if (epoch != _epoch) return;
        if (project == null) continue;
        projects[inv.projectId] = project;
        shown.add(inv);
      }
      if (epoch != _epoch) return;
      invitations.assignAll(shown);
    } on ProjectFailure {
      // Se conserva lo que ya estuviera en pantalla.
    } finally {
      isLoading.value = false;
    }
  }

  /// Acepta o rechaza. Devuelve `null` si salió bien o el mensaje para mostrar.
  ///
  /// Aceptar primero registra al miembro (idempotente) y después marca la
  /// invitación: si el segundo paso falla, reintentar no duplica a nadie.
  Future<String?> respond(
    ProjectInvitation invitation, {
    required bool accept,
  }) async {
    final userId = _currentUserId();
    if (userId.isEmpty || invitation.userId != userId) {
      return 'Esta invitación no es para tu cuenta.';
    }

    try {
      if (accept) {
        await _repository.addProjectMember(
          projectId: invitation.projectId,
          userId: userId,
          role: {'name': 'member'},
        );
      }
      await _repository.respondToInvitation(
        invitationId: invitation.id,
        accept: accept,
      );
    } on ProjectFailure catch (e) {
      return e.message;
    } catch (_) {
      return 'No se pudo responder la invitación.';
    }

    // Ya es miembro: su solicitud pendiente a este proyecto (si la había)
    // quedó obsoleta y el dueño no debería seguir viéndola. No es crítico: si
    // falla, el proyecto ya cuenta como Activo y esa solicitud no se muestra.
    if (accept) {
      try {
        await _repository.cancelPendingJoinRequests(
          projectId: invitation.projectId,
          userId: userId,
        );
      } on ProjectFailure {
        // Se limpia en la próxima oportunidad.
      }
    }

    invitations.removeWhere((i) => i.id == invitation.id);
    final project = projects[invitation.projectId];
    if (accept && project != null) _onAccepted(project);
    return null;
  }
}
