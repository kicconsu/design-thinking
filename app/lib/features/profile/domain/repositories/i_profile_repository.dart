import '../models/user_profile.dart';

abstract class IProfileRepository {
  /// Obtiene el perfil del usuario con sesión activa.
  Future<UserProfile> getMyProfile();

  /// Actualiza el resumen ("Sobre ti") y las habilidades del propio perfil.
  Future<UserProfile> updateMyProfile({
    required String bio,
    required List<String> skills,
  });
}
