import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_invitation.dart';
import 'package:imker/features/projects/domain/project_failure.dart';
import 'package:imker/features/projects/domain/repositories/i_project_repository.dart';

/// Repositorio de proyectos en memoria **parcial**: solo implementa lo que
/// leen las fichas de personas y la lista de invitaciones. Cualquier otra
/// llamada falla a propósito (`noSuchMethod`), para que una prueba no dependa
/// sin saberlo de algo que este doble no hace.
///
/// Cada `*Failure` hace que esa operación lance; así se prueba qué hace la
/// pantalla cuando una lectura no se puede completar.
class FakeProjectRepository implements IProjectRepository {
  // Ficha de una persona.
  List<Project> ofPerson = [];
  List<Project> participated = [];
  ProjectFailure? ofPersonFailure;
  ProjectFailure? participatedFailure;
  final participatedAsked = <String>[];

  // Invitaciones.
  List<ProjectInvitation> pending = [];
  List<String> memberOf = [];

  /// Proyectos que se pueden leer por id (el de cada invitación).
  final projects = <String, Project>{};
  ProjectFailure? invitationFailure;
  int pendingReads = 0;
  final accepted = <String>[];
  final declined = <String>[];

  @override
  Future<List<Project>> getProjectsOfPerson(String userId) async {
    if (ofPersonFailure != null) throw ofPersonFailure!;
    return ofPerson;
  }

  @override
  Future<List<Project>> getProjectsParticipatedBy(String userId) async {
    participatedAsked.add(userId);
    if (participatedFailure != null) throw participatedFailure!;
    return participated;
  }

  @override
  Future<List<ProjectInvitation>> getPendingInvitations(String userId) async {
    pendingReads++;
    return pending;
  }

  @override
  Future<List<String>> getMemberProjectIds(String userId) async => memberOf;

  @override
  Future<Project?> getProjectById(String id) async => projects[id];

  @override
  Future<void> acceptInvitation(ProjectInvitation invitation) async {
    if (invitationFailure != null) throw invitationFailure!;
    accepted.add(invitation.id);
  }

  @override
  Future<void> declineInvitation(ProjectInvitation invitation) async {
    if (invitationFailure != null) throw invitationFailure!;
    declined.add(invitation.id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
