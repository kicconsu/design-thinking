import 'package:roble/roble.dart';

import 'package:imker/core/utils/career_label.dart';
import 'package:imker/core/utils/string_list.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import '../../domain/profile_failure.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../datasources/i_profile_data_source.dart';

class ProfileRepository implements IProfileRepository {
  ProfileRepository(this._source);

  final IProfileDataSource _source;

  @override
  Future<UserProfile> getMyProfile() async {
    final row = await _guard(() => _source.readMyProfile(), isWrite: false);
    return _toProfile(row ?? const {});
  }

  @override
  Future<UserProfile> getProfileOf(String userId) async {
    final row = await _guard(() => _source.readProfileOf(userId), isWrite: false);
    return _toProfile(row ?? const {});
  }

  @override
  Future<void> ensureMyProfile({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _guard(() => _source.ensureMyProfile(name: trimmed), isWrite: false);
  }

  @override
  Future<UserProfile> updateMyProfile({
    required String program,
    required String institution,
    required String bio,
    required List<String> skills,
  }) async {
    final row = await _guard(
      () => _source.updateMyProfile(
        program: program,
        institution: institution,
        bio: bio,
        skills: skills,
      ),
      isWrite: true,
    );
    return _toProfile(row);
  }

  // ─── Traducción de errores ────────────────────────────────────────────────
  Future<T> _guard<T>(Future<T> Function() action, {required bool isWrite}) async {
    try {
      return await action();
    } on RobleApiNetworkException {
      throw const ProfileFailure('Sin conexión. Verifica tu red.');
    } on RobleApiTimeoutException {
      throw const ProfileFailure('La solicitud tardó demasiado. Intenta de nuevo.');
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 403) {
        throw ProfileFailure(
          isWrite
              ? 'No tienes permiso para editar este perfil.'
              : 'No tienes permiso para ver este perfil.',
        );
      }
      if (e.statusCode == 404) throw const ProfileFailure('No se encontró tu perfil.');
      throw ProfileFailure(e.message);
    } on RobleApiException catch (e) {
      throw ProfileFailure(e.message);
    }
  }

  // ─── Mapper ───────────────────────────────────────────────────────────────
  UserProfile _toProfile(Map<String, dynamic> row) {
    final career = parseCareer(row['career']);
    return UserProfile(
      name: (row['name'] as String?)?.trim() ?? '',
      program: career.program,
      institution: career.institution,
      bio: (row['description'] as String?) ?? '',
      skills: decodeStringList(row['skills']),
    );
  }
}
