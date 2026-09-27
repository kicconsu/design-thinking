/// A qué proyecto de Roble apunta la app.
///
/// El [contractId] no es un secreto —identifica el proyecto, no da acceso—,
/// así que puede ir en el repositorio. Se puede apuntar a otro proyecto sin
/// tocar el código:
///
/// ```bash
/// flutter run --dart-define=ROBLE_CONTRACT_ID=otro_proyecto
/// ```
abstract class RobleConfig {
  static const baseUrl = String.fromEnvironment(
    'ROBLE_BASE_URL',
    defaultValue: 'https://roble-api.test-openlab.uninorte.edu.co',
  );

  static const contractId = String.fromEnvironment(
    'ROBLE_CONTRACT_ID',
    defaultValue: 'imker_532a660dc4',
  );

  /// Botón de «Acceso rápido Dev» de la pantalla de login.
  ///
  /// Las credenciales de prueba viven en el servidor real, así que el botón
  /// sólo aparece si además se pide a propósito: `kDebugMode` solo no bastaba,
  /// cualquier `flutter run` de desarrollo estaba entrando con esas cuentas.
  ///
  /// ```bash
  /// flutter run --dart-define=DEV_LOGIN=true
  /// ```
  static const devLoginEnabled = bool.fromEnvironment('DEV_LOGIN');
}
