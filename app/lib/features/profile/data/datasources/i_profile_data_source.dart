abstract class IProfileDataSource {
  /// Fila de la tabla `profile` para el usuario con sesión activa, o `null`
  /// si todavía no tiene una.
  ///
  /// Nunca devuelve la fila de otra persona: si no se puede identificar la
  /// propia, no hay fila.
  Future<Map<String, dynamic>?> readMyProfile();

  /// Devuelve la fila propia y, si no existe, la crea con [name].
  ///
  /// Es la que se llama al entrar en la app para que ningún usuario se quede
  /// sin fila (los líderes ven los perfiles de los postulantes desde ahí).
  Future<Map<String, dynamic>?> ensureMyProfile({required String name});

  /// Actualiza `description` y `skills` en la fila del usuario y devuelve
  /// la fila ya actualizada.
  Future<Map<String, dynamic>> updateMyProfile({
    required String bio,
    required List<String> skills,
  });
}
