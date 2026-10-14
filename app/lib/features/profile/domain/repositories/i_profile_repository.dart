import '../models/user_profile.dart';

abstract class IProfileRepository {
  /// Obtiene el perfil del usuario con sesión activa.
  Future<UserProfile> getMyProfile();

  /// Garantiza que la sesión activa tenga fila en `profile`; si no existe, la
  /// crea con [name]. Se llama al entrar en la app, no en cada lectura.
  Future<void> ensureMyProfile({required String name});

  /// Actualiza carrera, resumen ("Sobre ti") y habilidades del propio perfil.
  Future<UserProfile> updateMyProfile({
    required String program,
    required String institution,
    required String bio,
    required List<String> skills,
  });
}
