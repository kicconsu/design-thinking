import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'package:imker/core/utils/career_label.dart';
import 'package:imker/core/utils/string_list.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_invitation.dart';
import 'package:imker/features/projects/domain/models/project_join_request.dart';

import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import '../datasources/i_project_data_source.dart';

class ProjectRepository with UiLoggy implements IProjectRepository {
  ProjectRepository(this._source);

  final IProjectDataSource _source;

  @override
  Future<List<Project>> getProjects() async {
    final rows = await _guard(() => _source.readProjects());
    final memberCounts = await _getMemberCounts();
    return rows.map((r) => _toProject(r, memberCounts)).toList();
  }

  @override
  Future<List<Project>> getProjectsByOwner(String ownerId) async {
    final rows = await _guard(() => _source.readProjectsByOwner(ownerId));
    final memberCounts = await _getMemberCounts();
    return rows.map((r) => _toProject(r, memberCounts)).toList();
  }

  @override
  Future<Project?> getProjectById(String id) async {
    final row = await _guard(() => _source.readProjectById(id));
    if (row == null) return null;
    final memberCounts = await _getMemberCounts(projectId: id);
    return _toProject(row, memberCounts);
  }

  @override
  Future<List<String>> validateInviteEmails(List<String> emails) async {
    final normalized = _normalizeEmails(emails);
    if (normalized.isEmpty) return [];
    final invitees = await _resolveInvitees(normalized);
    return normalized.where((email) => !invitees.containsKey(email)).toList();
  }

  @override
  Future<Project> createProject({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
    String imageUrl = '',
    List<String> inviteEmails = const [],
  }) async {
    final emails = _normalizeEmails(inviteEmails);

    // 1. Nada se escribe hasta que TODOS los correos estén verificados.
    // Roble no tiene transacciones: la única forma de que una creación sea
    // todo-o-nada es validar antes de tocar la base.
    final Map<String, String> invitees = emails.isEmpty
        ? const <String, String>{}
        : await _resolveInvitees(emails);
    final missing = emails
        .where((email) => !invitees.containsKey(email))
        .toList();
    // Quien crea el proyecto ya es su miembro `owner`: invitarse no tiene
    // sentido. Se compara por `user_id`, no por el texto del correo.
    final me = _source.currentUserId;
    if (me.isNotEmpty && invitees.values.contains(me)) {
      throw const ProjectFailure(
        'No puedes invitarte a tu propio proyecto: ya eres su creador.',
      );
    }
    if (missing.isNotEmpty) {
      throw ProjectFailure(
        'No existe una cuenta para ${missing.length == 1 ? 'el correo' : 'los correos'}: '
        '${missing.join(', ')}. El proyecto no se creó.',
      );
    }

    // 2. El proyecto.
    final project = await _createProjectRow(
      title: title,
      description: description,
      jobs: jobs,
      skills: skills,
      imageUrl: imageUrl,
    );
    if (emails.isEmpty) return project;

    // 3. Invitaciones, todas en una sola petición.
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final rows = [
      for (final email in emails)
        <String, dynamic>{
          'project_id': project.id,
          'email': email,
          'user_id': invitees[email],
          'status': 'pending',
          'createdAt': nowIso,
        },
    ];

    try {
      final inserted = await _source.createInvitations(rows);
      if (inserted.length != rows.length) {
        throw StateError(
          'El servidor rechazó ${rows.length - inserted.length} invitaciones',
        );
      }
    } catch (_) {
      // 4. Reversible: una invitación que no entra se lleva el proyecto
      // consigo, para que no quede una creación a medias.
      var undone = false;
      try {
        await _source.deleteProjectCascade(project.id);
        undone = true;
      } catch (_) {
        // El rollback también falló: se avisa, pero el error real es el de
        // las invitaciones.
      }
      throw ProjectFailure(
        undone
            ? 'No se pudieron enviar las invitaciones. El proyecto no se creó.'
            : 'No se pudieron enviar las invitaciones y no se pudo deshacer la '
                  'creación. Revisa tu lista de proyectos.',
      );
    }
    return project;
  }

  /// Cuerpo de la creación sin invitaciones: escribe la fila del proyecto.
  Future<Project> _createProjectRow({
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
    required String imageUrl,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'jobs': jobs,
      'skills': skills,
      'status': 'open',
    };

    final resultRow = await _guard(() => _source.createProject(payload));
    final createdId = (resultRow['_id'] ?? resultRow['id'])?.toString() ?? '';
    final memberCounts = await _getMemberCounts(projectId: createdId);
    return _toProject(resultRow, memberCounts);
  }

  @override
  Future<Project> updateProject({
    required String id,
    required String title,
    required String description,
    required List<String> jobs,
    required List<String> skills,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    // Las mismas reglas que al crear el proyecto.
    if (cleanTitle.isEmpty) {
      throw const ProjectFailure('El proyecto necesita un nombre.');
    }
    if (cleanDescription.isEmpty) {
      throw const ProjectFailure('El proyecto necesita una descripción.');
    }

    await _guard(
      () => _source.updateProject(id, {
        'title': cleanTitle,
        'description': cleanDescription,
        'jobs': _cleanList(jobs),
        'skills': _cleanList(skills),
      }),
    );
    final fresh = await getProjectById(id);
    if (fresh == null) {
      throw const ProjectFailure('No se encontró el proyecto.');
    }
    return fresh;
  }

  /// Sin vacíos ni repetidos (sin distinguir mayúsculas), conservando el orden.
  List<String> _cleanList(List<String> values) {
    final seen = <String>{};
    return [
      for (final v in values)
        if (v.trim().isNotEmpty && seen.add(v.trim().toLowerCase())) v.trim(),
    ];
  }

  List<String> _normalizeEmails(List<String> emails) => emails
      .map((email) => email.trim().toLowerCase())
      .where((email) => email.isNotEmpty)
      .toSet()
      .toList();

  /// Correo → user_id para los que sí tienen cuenta.
  Future<Map<String, String>> _resolveInvitees(List<String> emails) async {
    final List<Map<String, dynamic>> rows;
    try {
      rows = await _source.findUsersByEmails(emails);
    } on RobleApiNetworkException {
      throw const ProjectFailure('Sin conexión. Verifica tu red.');
    } on RobleApiTimeoutException {
      throw const ProjectFailure(
        'La solicitud tardó demasiado. Intenta de nuevo.',
      );
    } on RobleApiHttpException catch (e) {
      loggy.error('verify invitees error ${e.statusCode}: ${e.message}');
      throw ProjectFailure(e.message);
    } catch (e) {
      loggy.error('verify invitees error: $e');
      throw const ProjectFailure(
        'Error del servidor al verificar los correos invitados.',
      );
    }

    final resolved = <String, String>{};
    for (final row in rows) {
      final email = (row['email'] ?? '').toString().trim().toLowerCase();
      final userId = (row['user_id'] ?? row['userId'] ?? row['id'] ?? '')
          .toString()
          .trim();
      if (email.isNotEmpty && userId.isNotEmpty) {
        resolved[email] = userId;
      }
    }
    return resolved;
  }

  @override
  Future<ProjectJoinRequest> createJoinRequest({
    required String projectId,
    String? userId,
    dynamic status,
  }) async {
    final me = (userId != null && userId.isNotEmpty)
        ? userId
        : _source.currentUserId;
    await _assertOpen(projectId, 'solicitudes');
    if (me.isNotEmpty) await _assertCanApply(projectId: projectId, userId: me);

    final payload = <String, dynamic>{
      'project_id': projectId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'status': status ?? 'pending',
    };

    final resultRow = await _guard(() => _source.createJoinRequest(payload));
    return _toProjectJoinRequest(resultRow);
  }

  @override
  Future<Project> closeProject(String projectId) async {
    // Idempotente: cerrar uno ya cerrado deja el mismo resultado.
    await _guard(() => _source.updateProject(projectId, {'status': 'closed'}));
    final fresh = await getProjectById(projectId);
    if (fresh == null) throw const ProjectFailure('No se encontró el proyecto.');
    return fresh;
  }

  /// Un proyecto cerrado ya no recibe [what] (solicitudes o invitaciones).
  /// Solo bloquea si el proyecto está explícitamente `closed`: uno que no se
  /// encuentra (p. ej. un proyecto demo) sigue el camino de siempre.
  Future<void> _assertOpen(String projectId, String what) async {
    final row = await _guard(() => _source.readProjectById(projectId));
    if (row != null && row['status']?.toString() == 'closed') {
      throw ProjectFailure('Este proyecto está cerrado y ya no recibe $what.');
    }
  }

  /// Solo se postula desde "nada" o "guardado": quien ya colabora, ya postuló
  /// o ya tiene una invitación pendiente al mismo proyecto no puede volver a
  /// hacerlo. Lecturas estrictas: si fallan, la excepción sube.
  Future<void> _assertCanApply({
    required String projectId,
    required String userId,
  }) async {
    if ((await getMemberProjectIds(userId)).contains(projectId)) {
      throw const ProjectFailure('Ya colaboras en este proyecto.');
    }
    final mine = await getJoinRequestsByUser(userId);
    if (mine.any(
      (r) =>
          r.projectId == projectId && r.statusState.toLowerCase() == 'pending',
    )) {
      throw const ProjectFailure('Ya tienes una postulación pendiente aquí.');
    }
    final invitations = await getPendingInvitations(userId);
    if (invitations.any((i) => i.projectId == projectId)) {
      throw const ProjectFailure(
        'Ya te invitaron a este proyecto: responde la invitación.',
      );
    }
  }

  @override
  Future<List<ProjectJoinRequest>> getJoinRequestsByUser(String userId) async {
    final rows = await _guard(() => _source.readJoinRequestsByUser(userId));
    return rows.map(_toProjectJoinRequest).toList();
  }

  @override
  Future<List<ProjectJoinRequest>> getJoinRequestsForProject(
    String projectId,
  ) async {
    final rows = await _guard(
      () => _source.readJoinRequestsForProject(projectId),
    );
    return rows.map(_toProjectJoinRequest).toList();
  }

  @override
  Future<ProjectJoinRequest> updateJoinRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    final resultRow = await _guard(
      () => _source.updateJoinRequestStatus(
        requestId: requestId,
        status: status,
        reviewedBy: reviewedBy,
        reviewNote: reviewNote,
      ),
    );
    return _toProjectJoinRequest(resultRow);
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _guard(() => _source.readUserProfile(userId));
  }

  @override
  Future<void> addProjectMember({
    required String projectId,
    required String userId,
    Map<String, dynamic>? role,
  }) async {
    await _guard(
      () => _source.addProjectMember(
        projectId: projectId,
        userId: userId,
        role: role,
      ),
    );
  }

  // ─── Guardados (project_saved) ────────────────────────────────────────────
  @override
  Future<List<String>> getSavedProjectIds(String userId) async {
    if (userId.isEmpty) return [];
    final rows = await _guard(() => _source.readSavedByUser(userId));
    return rows
        .map((r) => (r['project_id'] ?? r['projectId'])?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  @override
  Future<void> saveProject({
    required String userId,
    required String projectId,
  }) async {
    if (userId.isEmpty || projectId.isEmpty) return;
    await _guard(
      () => _source.createSaved(userId: userId, projectId: projectId),
    );
  }

  @override
  Future<void> unsaveProject({
    required String userId,
    required String projectId,
  }) async {
    if (userId.isEmpty || projectId.isEmpty) return;
    await _guard(
      () => _source.deleteSaved(userId: userId, projectId: projectId),
    );
  }

  @override
  Future<int> cancelPendingJoinRequests({
    required String projectId,
    required String userId,
    String? cancelledBy,
  }) async {
    final mine = await getJoinRequestsByUser(userId);
    final stale = mine.where(
      (r) =>
          r.projectId == projectId &&
          r.statusState.toLowerCase() == 'pending' &&
          r.id.isNotEmpty,
    );
    for (final request in stale) {
      // `reviewed_by` es quien cambió el estado.
      await _guard(
        () => _source.updateJoinRequestStatus(
          requestId: request.id,
          status: 'cancelled',
          reviewedBy: cancelledBy ?? userId,
        ),
      );
    }
    return stale.length;
  }

  // ─── Entrar a un proyecto ─────────────────────────────────────────────────
  static const _memberRole = {'name': 'member'};

  @override
  Future<void> acceptJoinRequest({
    required String requestId,
    required String projectId,
    required String applicantId,
    required String reviewerId,
  }) async {
    // Una solicitud que quedó pendiente antes de cerrar ya no se puede aceptar.
    await _assertOpen(projectId, 'solicitudes');
    await _guard(
      () => _source.addProjectMember(
        projectId: projectId,
        userId: applicantId,
        role: _memberRole,
      ),
    );
    await _guard(
      () => _source.updateJoinRequestStatus(
        requestId: requestId,
        status: 'accepted',
        reviewedBy: reviewerId,
      ),
    );
    // Ya es miembro: lo demás que tuviera abierto hacia este proyecto sobra.
    await _bestEffort(
      () => cancelPendingJoinRequests(
        projectId: projectId,
        userId: applicantId,
        cancelledBy: reviewerId,
      ),
    );
    await _bestEffort(() => _cancelPendingInvitations(projectId, applicantId));
  }

  @override
  Future<void> rejectJoinRequest({
    required String requestId,
    required String reviewerId,
  }) async {
    await _guard(
      () => _source.updateJoinRequestStatus(
        requestId: requestId,
        status: 'rejected',
        reviewedBy: reviewerId,
      ),
    );
  }

  @override
  Future<void> acceptInvitation(ProjectInvitation invitation) async {
    await _assertOpen(invitation.projectId, 'invitaciones');
    await _guard(
      () => _source.addProjectMember(
        projectId: invitation.projectId,
        userId: invitation.userId,
        role: _memberRole,
      ),
    );
    await _guard(
      () => _source.updateInvitationStatus(
        invitationId: invitation.id,
        status: 'accepted',
      ),
    );
    await _bestEffort(
      () => cancelPendingJoinRequests(
        projectId: invitation.projectId,
        userId: invitation.userId,
      ),
    );
  }

  @override
  Future<void> declineInvitation(ProjectInvitation invitation) async {
    await _guard(
      () => _source.updateInvitationStatus(
        invitationId: invitation.id,
        status: 'declined',
      ),
    );
  }

  @override
  Future<List<String>> getActiveMemberUserIds(String projectId) async {
    final rows = await _guard(
      () => _source.readProjectMembers(projectId: projectId),
    );
    return {
      for (final r in rows)
        if (_isActiveMember(r) && (r['user_id']?.toString() ?? '').isNotEmpty)
          r['user_id'].toString(),
    }.toList();
  }

  @override
  Future<void> leaveProject({
    required String projectId,
    required String userId,
  }) async {
    if (projectId.isEmpty || userId.isEmpty) {
      throw const ProjectFailure('Falta el proyecto o la sesión.');
    }
    if (await _isCreator(projectId, userId)) {
      throw const ProjectFailure('El creador no puede salir del proyecto.');
    }
    await _guard(() => _source.endMembership(projectId, userId, 'left'));
    // Salir borra el propio guardado; quedaría en Guardados un proyecto del
    // que la persona acaba de irse.
    await _bestEffort(
      () => unsaveProject(userId: userId, projectId: projectId),
    );
  }

  @override
  Future<void> removeMember({
    required String projectId,
    required String memberUserId,
    required String requestedBy,
  }) async {
    if (projectId.isEmpty || memberUserId.isEmpty || requestedBy.isEmpty) {
      throw const ProjectFailure('Falta el proyecto o la sesión.');
    }
    if (memberUserId == requestedBy) {
      throw const ProjectFailure('Para irte del proyecto usa «Salir».');
    }
    if (!await _isCreator(projectId, requestedBy)) {
      throw const ProjectFailure('Solo el creador puede quitar a alguien.');
    }
    if (await _isCreator(projectId, memberUserId)) {
      throw const ProjectFailure('No se puede quitar al creador.');
    }
    await _guard(
      () => _source.endMembership(projectId, memberUserId, 'removed'),
    );
  }

  /// Es el creador si el proyecto es suyo (`_owner`) o si su estancia activa
  /// tiene el papel `owner`. Se miran las dos cosas: ninguna es infalible
  /// (filas viejas sin papel, lecturas parciales).
  Future<bool> _isCreator(String projectId, String userId) async {
    final project = await _guard(() => _source.readProjectById(projectId));
    final owner =
        (project?['_owner'] ?? project?['owner'])?.toString().trim() ?? '';
    if (owner.isNotEmpty && owner == userId) return true;
    final rows = await _guard(
      () => _source.readProjectMembers(projectId: projectId),
    );
    return rows.any(
      (r) =>
          r['user_id']?.toString() == userId &&
          _isActiveMember(r) &&
          _roleName(r['role']) == 'owner',
    );
  }

  /// Cierra las invitaciones `pending` de esa persona a ese proyecto.
  Future<void> _cancelPendingInvitations(
    String projectId,
    String userId,
  ) async {
    final rows = await _guard(() => _source.readInvitationsForUser(userId));
    for (final row in rows.map(_toInvitation)) {
      if (row.projectId != projectId || !row.isPending) continue;
      await _guard(
        () => _source.updateInvitationStatus(
          invitationId: row.id,
          status: 'cancelled',
        ),
      );
    }
  }

  /// Limpieza que no debe tumbar la operación principal: si falla, la fila
  /// obsoleta no se muestra (las lecturas ya la filtran) y se cierra después.
  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } on ProjectFailure catch (e) {
      loggy.warning('limpieza pendiente: ${e.message}');
    }
  }

  /// Una fila de `project_member` sin `status` (anterior a la columna) cuenta
  /// como activa.
  bool _isActiveMember(Map<String, dynamic> row) =>
      (row['status']?.toString() ?? 'active') == 'active';

  // ─── Miembros ─────────────────────────────────────────────────────────────
  @override
  Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    final rows = await _guard(
      () => _source.readProjectMembers(projectId: projectId),
    );

    // La lectura puede devolver filas de otros proyectos (según el modo de
    // lectura) y Roble no garantiza unicidad: se filtra y se cuenta una vez.
    final seen = <String>{};
    final active = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (!_isActiveMember(row)) continue;
      if ((row['project_id'] ?? row['projectId'])?.toString() != projectId) {
        continue;
      }
      final userId = (row['user_id'] ?? row['userId'])?.toString() ?? '';
      if (userId.isEmpty || !seen.add(userId)) continue;
      active.add(row);
    }

    final profiles = await Future.wait([
      for (final row in active) _profileOrNull(row['user_id'].toString()),
    ]);

    final members = <ProjectMember>[
      for (var i = 0; i < active.length; i++) _toMember(active[i], profiles[i]),
    ];
    // Dart ordena de forma estable: a igual criterio se conserva el orden.
    members.sort((a, b) {
      if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
      final aj = a.joinedAt;
      final bj = b.joinedAt;
      // Sin fecha de ingreso, al final.
      if (aj == null && bj == null) return 0;
      if (aj == null) return 1;
      if (bj == null) return -1;
      return aj.compareTo(bj);
    });
    return members;
  }

  /// El perfil es un adorno de la lista: sin él se muestra un nombre genérico.
  Future<Map<String, dynamic>?> _profileOrNull(String userId) async {
    try {
      return await _source.readUserProfile(userId);
    } catch (_) {
      return null;
    }
  }

  ProjectMember _toMember(
    Map<String, dynamic> row,
    Map<String, dynamic>? profile,
  ) {
    final userId = row['user_id'].toString();
    final name = (profile?['name'] as String?)?.trim() ?? '';
    return ProjectMember(
      userId: userId,
      name: name.isNotEmpty
          ? name
          : (userId.length > 8
                ? 'Usuario ${userId.substring(0, 8)}'
                : 'Miembro'),
      career: formatCareer(profile?['career']),
      role: ProjectMemberRole.fromName(_roleName(row['role'])),
      joinedAt: DateTime.tryParse(row['joinedAt']?.toString() ?? ''),
    );
  }

  // ─── Invitaciones ─────────────────────────────────────────────────────────
  @override
  Future<List<ProjectInvitation>> getPendingInvitations(String userId) async {
    final rows = await _guard(() => _source.readInvitationsForUser(userId));
    return rows
        .map(_toInvitation)
        .where(
          (i) =>
              i.isPending &&
              i.projectId.isNotEmpty &&
              // Una invitación de uno mismo (anterior al bloqueo) no cuenta.
              i.invitedBy != userId,
        )
        .toList();
  }

  @override
  Future<void> respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    await _guard(
      () => _source.updateInvitationStatus(
        invitationId: invitationId,
        status: accept ? 'accepted' : 'declined',
      ),
    );
  }

  @override
  Future<List<Project>> getProjectsOfPerson(String userId) async {
    if (userId.isEmpty) return const [];
    final created = await getProjectsByOwner(userId);
    final createdIds = {for (final p in created) p.id};
    final collaborating = <Project>[];
    for (final id in await getMemberProjectIds(userId)) {
      if (createdIds.contains(id)) continue;
      final project = await getProjectById(id);
      if (project != null) collaborating.add(project);
    }
    return [...created, ...collaborating];
  }

  @override
  Future<List<String>> getMemberProjectIds(String userId) async {
    final rows = await _guard(() => _source.readMembershipsByUser(userId));
    return {
      for (final r in rows)
        if (_isActiveMember(r) &&
            _roleName(r['role']) != 'owner' &&
            (r['project_id']?.toString() ?? '').isNotEmpty)
          r['project_id'].toString(),
    }.toList();
  }

  String _roleName(Object? role) {
    if (role is Map) return (role['name'] ?? '').toString();
    return role?.toString() ?? '';
  }

  ProjectInvitation _toInvitation(Map<String, dynamic> row) =>
      ProjectInvitation(
        id: (row['_id'] ?? row['id'])?.toString() ?? '',
        projectId: row['project_id']?.toString() ?? '',
        userId: row['user_id']?.toString() ?? '',
        email: row['email']?.toString() ?? '',
        status: row['status']?.toString() ?? 'pending',
        createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? ''),
        respondedAt: DateTime.tryParse(row['respondedAt']?.toString() ?? ''),
        invitedBy: row['_owner']?.toString(),
      );

  // ─── Traducción de errores ────────────────────────────────────────────────
  // Las excepciones se atrapan de más específica a más general; si no se
  // respeta el orden, RobleApiException (clase base) absorbería todo lo demás.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RobleApiNetworkException {
      throw const ProjectFailure('Sin conexión. Verifica tu red.');
    } on RobleApiTimeoutException {
      throw const ProjectFailure(
        'La solicitud tardó demasiado. Intenta de nuevo.',
      );
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 403) {
        throw const ProjectFailure('No tienes permiso para ver esto.');
      }
      if (e.statusCode == 404) {
        throw const ProjectFailure('No se encontró el registro.');
      }
      // Para 400 y otros, mostrar el mensaje real del servidor para facilitar diagnóstico.
      final msg = e.message.isNotEmpty
          ? e.message
          : 'Error HTTP ${e.statusCode}';
      throw ProjectFailure(msg);
    } on RobleApiException catch (e) {
      final msg = e.message.isNotEmpty
          ? e.message
          : 'Error desconocido del servidor';
      throw ProjectFailure(msg);
    }
  }

  /// Miembros activos por proyecto. Una persona cuenta una sola vez.
  Future<Map<String, int>> _getMemberCounts({String? projectId}) async {
    final Map<String, int> counts = {};
    try {
      final memberRows = await _source.readProjectMembers(projectId: projectId);
      final seen = <String>{};
      for (final row in memberRows) {
        if (!_isActiveMember(row)) continue;
        final pId = (row['project_id'] ?? row['projectId'])?.toString() ?? '';
        final uId =
            (row['user_id'] ?? row['userId'] ?? row['_owner'])?.toString() ??
            '';
        if (pId.isEmpty) continue;
        // ROBLE no garantiza unicidad: una persona cuenta una sola vez.
        if (uId.isNotEmpty && !seen.add('$pId/$uId')) continue;
        counts[pId] = (counts[pId] ?? 0) + 1;
      }
    } catch (_) {}
    return counts;
  }

  // ─── Mappers ──────────────────────────────────────────────────────────────
  Project _toProject(
    Map<String, dynamic> row, [
    Map<String, int>? memberCounts,
  ]) {
    final id = (row['_id'] ?? row['id'])?.toString() ?? '';
    final owner =
        (row['_owner'] ?? row['owner'] ?? row['user_id'])?.toString() ?? '';

    // El creador siempre es miembro: sin filas legibles cuenta como uno.
    final memberCount = memberCounts?[id] ?? (owner.isNotEmpty ? 1 : 0);

    return Project(
      id: id,
      owner: owner,
      title: (row['title'] ?? '') as String,
      imageUrl: (row['imageUrl'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      jobs: decodeStringList(row['jobs']),
      skills: decodeStringList(row['skills']),
      status: (row['status'] as String?) ?? 'open',
      memberCount: memberCount,
      // Las filas anteriores a la columna vienen con null: cuentan como 0.
      progress: ((row['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100),
    );
  }

  ProjectJoinRequest _toProjectJoinRequest(Map<String, dynamic> row) {
    Map<String, dynamic> parsedStatus = {};
    final rawStatus = row['status'];
    if (rawStatus is Map<String, dynamic>) {
      parsedStatus = rawStatus;
    } else if (rawStatus is Map) {
      parsedStatus = Map<String, dynamic>.from(rawStatus);
    } else if (rawStatus is String) {
      try {
        final decoded = jsonDecode(rawStatus);
        if (decoded is Map<String, dynamic>) {
          parsedStatus = decoded;
        } else if (decoded is Map) {
          parsedStatus = Map<String, dynamic>.from(decoded);
        } else {
          parsedStatus = {'state': rawStatus};
        }
      } catch (_) {
        parsedStatus = {'state': rawStatus};
      }
    }

    return ProjectJoinRequest(
      id: (row['_id'] ?? row['id'])?.toString() ?? '',
      userId: (row['user_id'] ?? row['_owner'])?.toString() ?? '',
      projectId: (row['project_id'])?.toString() ?? '',
      status: parsedStatus,
      createdAt: row['createdAt'] != null
          ? DateTime.tryParse(row['createdAt'].toString())
          : null,
      updatedAt: row['updatedAt'] != null
          ? DateTime.tryParse(row['updatedAt'].toString())
          : null,
      reviewedBy: row['reviewed_by']?.toString(),
      reviewNote: row['reviewNote']?.toString(),
      owner: row['_owner']?.toString(),
    );
  }
}
