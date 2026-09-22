import 'package:roble/roble.dart';

/// El cliente de Roble, uno solo para toda la app.
///
/// Se crea una vez en [main.dart] y se inyecta con [Get.put]. Crear uno por
/// pantalla le daría a cada copia su propia sesión. Los repositorios lo
/// reciben inyectado a través de sus datasources.
class RobleClient {
  RobleClient({
    required String baseUrl,
    required String contractId,
    Duration timeout = const Duration(seconds: 10),
  }) : db = RobleApiDataBase(
          config: RobleApiConfig.fromContract(
            baseUrl: baseUrl,
            contractId: contractId,
            timeout: timeout,
          ),
        );

  /// Constructor alternativo para pruebas.
  RobleClient.withDatabase(this.db);

  final RobleApiDataBase db;

  /// El [userId] de la sesión activa, cacheado.
  ///
  /// El paquete guarda los tokens pero no el perfil, y [currentUser()] hace
  /// un viaje al servidor. Varias lecturas dependen de quién mira, así que
  /// preguntarlo en cada una sería una llamada de más. Lo escribe el
  /// repositorio de auth al entrar y lo borra al salir.
  String? currentUserId;

  // ─── Nombres de tablas en un solo sitio ─────────────────────────────────
  // Un typo aquí es un 404 y no un error de compilación.
  // Centralizar evita que se repitan por toda la app.

  static const projects = 'project';
  static const profileTable = 'profile';

  // ─── Lectura pública vs. autenticada ─────────────────────────────────────

  /// Si quien mira no tiene cuenta —o tiene sesión de invitado—.
  ///
  /// Un invitado tiene [isLoggedIn == true] pero el rol `anonymous`, que solo
  /// lee sus propias filas. Mirar únicamente [isLoggedIn] mandaría el feed del
  /// invitado por la lectura normal y devolvería ninguna fila sin ningún error:
  /// la pantalla sale vacía y no hay nada que depurar.
  bool get readsPublicly => !db.isLoggedIn || db.isAnonymous;

  /// El feed de proyectos se lee sin sesión, pero [publicRead] solo funciona
  /// si la tabla está marcada como pública en la consola de Roble.
  ///
  /// Con una cuenta de verdad se usa la lectura normal, que no depende de esa
  /// marca. Los filtros viajan en ambos caminos.
  Future<List<Map<String, dynamic>>> readPublicOrPrivate(
    String table, {
    Map<String, dynamic>? filters,
  }) => readsPublicly
      ? db.publicRead(table, filters: filters)
      : db.read(table, filters: filters);
}
