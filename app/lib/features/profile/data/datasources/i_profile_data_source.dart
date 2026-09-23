abstract class IProfileDataSource {
  /// Fila de la tabla `profile` para el usuario con sesión activa, o null
  /// si todavía no tiene una (no debería pasar: se crea en el signup/upgrade).
  Future<Map<String, dynamic>?> readMyProfile();

  /// Actualiza `description` y `skills` en la fila del usuario y devuelve
  /// la fila ya actualizada.
  Future<Map<String, dynamic>> updateMyProfile({
    required String bio,
    required List<String> skills,
  });
}
