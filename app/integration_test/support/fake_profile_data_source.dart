import 'package:imker/core/utils/career_label.dart';
import 'package:imker/features/profile/data/datasources/i_profile_data_source.dart';

/// Perfiles de prueba: una fila por persona, en memoria.
///
/// Las filas tienen la misma forma que las de la tabla `profile`
/// (`name`, `career`, `description`, `skills`, `profilePicture`).
class FakeProfileDataSource implements IProfileDataSource {
  FakeProfileDataSource({
    required this.currentUserId,
    Map<String, Map<String, dynamic>> profiles = const {},
  }) : _profiles = {
         for (final e in profiles.entries) e.key: Map<String, dynamic>.of(e.value),
       };

  /// Quién tiene la sesión.
  final String currentUserId;

  final Map<String, Map<String, dynamic>> _profiles;

  @override
  Future<Map<String, dynamic>?> readMyProfile() async =>
      _profiles[currentUserId];

  @override
  Future<Map<String, dynamic>?> readProfileOf(String userId) async =>
      _profiles[userId];

  @override
  Future<Map<String, dynamic>?> ensureMyProfile({required String name}) async {
    return _profiles.putIfAbsent(
      currentUserId,
      () => {
        '_owner': currentUserId,
        'name': name,
        'career': <String, dynamic>{},
        'skills': <dynamic>[],
        'profilePicture': '',
        'description': '',
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateMyProfile({
    required String program,
    required String institution,
    required String bio,
    required List<String> skills,
  }) async {
    final row = await ensureMyProfile(name: '') ?? <String, dynamic>{};
    row['career'] = careerToJson(program: program, institution: institution);
    row['description'] = bio;
    row['skills'] = skills;
    return row;
  }
}
