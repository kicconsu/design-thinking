abstract class AppRoutes {
  /// Pantalla de carga — restaura sesión y redirige.
  static const splash = '/';

  /// (Discover · Projects · Profile).
  static const home = '/home';

  /// Primeros datos del perfil tras crear la cuenta (omitible).
  static const onboarding = '/onboarding';

  static const login = '/auth/login';

  static const register = '/auth/register';

  /// Convierte la sesión de invitado en una cuenta real (upgradeAccount).
  static const upgradeAccount = '/auth/upgrade';

  /// Recibe [String] projectId como argumento.
  static const projectDetail = '/project';
}
