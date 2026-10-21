import 'dart:async';

import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/profile/domain/profile_failure.dart';
import 'package:imker/features/profile/domain/repositories/i_profile_repository.dart';

/// Repositorio de perfiles en memoria para probar quien lo usa.
///
/// - [me] es el perfil de quien tiene la sesión; [other] es el que se
///   devuelve para cualquier otra persona (con [withName], con el nombre
///   «Nombre de» seguido del id).
/// - [failure] hace que las lecturas y la edición lancen; [gate] deja la
///   lectura del perfil propio esperando a que la prueba la libere.
/// - Recuerda a quién se pidió ([asked]), los nombres con que se garantizó la
///   fila ([ensured]) y lo que se guardó ([saved]).
class FakeProfileRepository implements IProfileRepository {
  FakeProfileRepository({
    this.me = const UserProfile(),
    this.other = litigante,
    this.withName = false,
  });

  /// Un perfil completo de ejemplo, el que se muestra para otras personas.
  static const litigante = UserProfile(
    program: 'Derecho',
    institution: 'Uninorte',
    bio: 'Litigante en formación.',
    skills: ['Oratoria'],
  );

  UserProfile me;
  UserProfile other;
  bool withName;

  ProfileFailure? failure;
  Completer<UserProfile>? gate;

  /// Hace fallar `ensureMyProfile` (la lectura y la edición no se afectan).
  bool ensureFails = false;

  final asked = <String>[];
  final ensured = <String>[];
  final saved = <UserProfile>[];

  @override
  Future<UserProfile> getMyProfile() async {
    final pending = gate;
    if (pending != null) return pending.future;
    if (failure != null) throw failure!;
    return me;
  }

  @override
  Future<UserProfile> getProfileOf(String userId) async {
    asked.add(userId);
    if (failure != null) throw failure!;
    if (!withName) return other;
    return UserProfile(
      name: 'Nombre de $userId',
      program: other.program,
      institution: other.institution,
      bio: other.bio,
      skills: other.skills,
    );
  }

  @override
  Future<void> ensureMyProfile({required String name}) async {
    if (ensureFails) throw StateError('sin red');
    ensured.add(name);
  }

  @override
  Future<UserProfile> updateMyProfile({
    required String program,
    required String institution,
    required String bio,
    required List<String> skills,
  }) async {
    if (failure != null) throw failure!;
    final profile = UserProfile(
      program: program,
      institution: institution,
      bio: bio,
      skills: skills,
    );
    saved.add(profile);
    return me = profile;
  }
}
