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

  /// El `userId` de la sesión activa: el `sub` del JWT, que es exactamente lo
  /// que el servidor escribe en `_owner` de cada fila.
  ///
  /// No hay caché propio: el paquete lo saca del token en memoria sin ir al
  /// servidor.
  String? get currentUserId => db.currentUserId;

  /// ¿Esta fila es del que está dentro?
  ///
  /// `_owner` es un uuid de usuario; a veces viene vacío (filas antiguas o
  /// creadas con clave publicable) y eso nunca es nadie.
  bool matchesUser(String? owner) {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return false;
    if (owner == null || owner.trim().isEmpty) return false;
    return owner.trim() == userId;
  }

  // ─── Nombres de tablas en un solo sitio ─────────────────────────────────
  // Un typo aquí es un 404 y no un error de compilación.
  // Centralizar evita que se repitan por toda la app.

  static const projects = 'project';
  static const profileTable = 'profile';
  static const projectJoinRequests = 'project_join_request';
  static const projectMembers = 'project_member';
  static const projectSaved = 'project_saved';

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
