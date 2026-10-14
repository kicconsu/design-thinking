import 'package:get/get.dart';

import 'package:imker/core/utils/career_label.dart';
import 'package:imker/core/utils/string_list.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';

import '../../domain/models/applicant.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_join_request.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import 'user_projects_controller.dart';

/// Solicitudes de colaboración recibidas en los proyectos del usuario y la
/// decisión (aceptar / rechazar) sobre cada una.
class CollaborationRequestsController extends GetxController {
  CollaborationRequestsController({
    IProjectRepository? repository,
    String Function()? currentUserId,
    bool Function(Project)? isOwner,
  }) : _repository = repository ?? Get.find<IProjectRepository>(),
       _currentUserId =
           currentUserId ??
           (() => Get.find<AuthenticationController>().loggedUserId),
       _isOwner =
           isOwner ?? ((p) => Get.find<UserProjectsController>().isOwner(p));

  final IProjectRepository _repository;
  final String Function() _currentUserId;
  final bool Function(Project) _isOwner;

  final RxList<Applicant> applicants = <Applicant>[].obs;

  /// Sube con cada [clear]; ver `InvitationsController`.
  int _epoch = 0;

  /// Olvida las solicitudes de la sesión que se va.
  void clear() {
    _epoch++;
    applicants.clear();
  }

  List<Applicant> applicantsFor(String projectId) =>
      applicants.where((a) => a.projectId == projectId).toList();

  int pendingCount(String projectId) => applicantsFor(projectId).length;

  /// Lee las solicitudes `pending` de un proyecto y reemplaza las que había
  /// de ese proyecto: lo ya decidido (aquí o desde otro dispositivo) sale.
  Future<void> fetchForProject(String projectId) async {
    final epoch = _epoch;
    try {
      final requests = await _repository.getJoinRequestsForProject(projectId);
      // Quien ya colabora (p. ej. entró por una invitación) no necesita que se
      // le acepte nada.
      final members = (await _repository.getActiveMemberUserIds(projectId))
          .toSet();
      final loaded = <Applicant>[];
      for (final req in requests) {
        if (req.statusState.toLowerCase() != 'pending') continue;
        if (members.contains(req.userId)) continue;
        loaded.add(await _toApplicant(req));
      }
      if (epoch != _epoch) return;
      applicants.removeWhere((a) => a.projectId == projectId);
      applicants.addAll(loaded);
    } on ProjectFailure {
      // Se conserva lo que ya estuviera en pantalla.
    }
  }

  Future<void> fetchForProjects(Iterable<String> projectIds) async {
    for (final id in projectIds) {
      await fetchForProject(id);
    }
  }

  /// Acepta o rechaza una solicitud. Devuelve `null` si salió bien o el
  /// mensaje para mostrar.
  ///
  /// La regla (miembro primero, estado después, limpieza al final) vive en el
  /// repositorio; aquí solo se pide y se informa.
  Future<String?> decide(
    Applicant applicant, {
    required Project project,
    required bool accepted,
  }) async {
    if (!_isOwner(project)) {
      return 'Solo quien creó el proyecto puede decidir sobre las solicitudes.';
    }
    final reviewerId = _currentUserId();
    if (reviewerId.isEmpty || applicant.userId.isEmpty) {
      return 'No se pudo identificar a las personas de la solicitud.';
    }

    try {
      if (accepted) {
        await _repository.acceptJoinRequest(
          requestId: applicant.id,
          projectId: applicant.projectId,
          applicantId: applicant.userId,
          reviewerId: reviewerId,
        );
      } else {
        await _repository.rejectJoinRequest(
          requestId: applicant.id,
          reviewerId: reviewerId,
        );
      }
    } on ProjectFailure catch (e) {
      return e.message;
    } catch (_) {
      return 'No se pudo actualizar la solicitud.';
    }

    applicants.removeWhere((a) => a.id == applicant.id);
    if (accepted && Get.isRegistered<UserProjectsController>()) {
      await Get.find<UserProjectsController>().refreshProject(
        applicant.projectId,
      );
    }
    return null;
  }

  Future<Applicant> _toApplicant(ProjectJoinRequest req) async {
    Map<String, dynamic>? profile;
    if (req.userId.isNotEmpty) {
      try {
        profile = await _repository.getUserProfile(req.userId);
      } on ProjectFailure {
        // Sin perfil legible se muestra la solicitud con datos mínimos.
      }
    }

    final name = (profile?['name'] as String?)?.trim() ?? '';
    final bio = (profile?['description'] as String?)?.trim() ?? '';
    return Applicant(
      id: req.id,
      projectId: req.projectId,
      userId: req.userId,
      name: name.isNotEmpty
          ? name
          : (req.userId.length > 8
                ? 'Usuario ${req.userId.substring(0, 8)}'
                : 'Aspirante'),
      academicInfo: formatCareer(profile?['career']),
      requestedRole: 'Colaborador',
      appliedAgo: _formatAgo(req.createdAt),
      commonProjects: 0,
      commitmentScore: 0,
      onTimeScore: 0,
      responseRateScore: 0,
      completedProjectsScore: 0,
      bio: bio.isNotEmpty
          ? bio
          : 'Esta persona aún no escribió una descripción.',
      skills: decodeStringList(profile?['skills']),
      experience: const [],
      statusState: req.statusState,
    );
  }

  String _formatAgo(DateTime? date) {
    if (date == null) return 'Recientemente';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}
