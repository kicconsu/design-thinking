import 'dart:convert';

import 'package:roble/roble.dart';

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
  Future<UserProfile> updateMyProfile({
    required String bio,
    required List<String> skills,
  }) async {
    final row = await _guard(
      () => _source.updateMyProfile(bio: bio, skills: skills),
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
  UserProfile _toProfile(Map<String, dynamic> row) => UserProfile(
    academicInfo: _formatCareer(row['career']),
    bio: (row['description'] as String?) ?? '',
    skills: _parseList(row['skills']),
    // Placeholder hasta que exista un algoritmo real de reputación.
    commitmentScore: 83,
    onTimeScore: 83,
    responseRateScore: 83,
    completedProjectsScore: 83,
  );

  /// `career` no tiene todavía una convención definida por el equipo de
  /// backend: puede llegar como texto plano o como un objeto
  /// `{"program": ..., "institution": ...}`. Se manejan ambos casos y,
  /// si no calza ninguno, se muestra vacío en vez de fallar.
  static String _formatCareer(Object? value) {
    if (value == null) return '';
    Object? raw = value;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return '';
      try {
        raw = jsonDecode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    if (raw is Map) {
      final program = (raw['program'] as String?)?.trim() ?? '';
      final institution = (raw['institution'] as String?)?.trim() ?? '';
      if (program.isEmpty && institution.isEmpty) return '';
      if (program.isEmpty) return institution;
      if (institution.isEmpty) return program;
      return '$program - $institution';
    }
    return '';
  }

  /// A diferencia de `ProjectRepository` (donde las columnas json se guardan
  /// como `{"values": [...]}`), la tabla `profile` guarda `skills` como una
  /// lista plana — ver `AuthenticationSourceService._syncProfile`. Se maneja
  /// también el formato envuelto por si acaso, para no romper si cambia.
  static List<String> _parseList(Object? value) {
    if (value == null) return const [];
    Object? raw = value;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const [];
      try {
        raw = jsonDecode(trimmed);
      } catch (_) {
        return const [];
      }
    }
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is Map && raw['values'] is List) {
      return (raw['values'] as List).map((e) => e.toString()).toList();
    }
    return const [];
  }
}
