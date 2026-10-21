/// Datos de prueba de las pruebas de integración.
///
/// Son los únicos datos que ve la app durante esas pruebas: filas con la misma
/// forma que devolvería Roble, escritas a mano. Todas las pruebas comparten el
/// mismo proyecto y las mismas tres personas; cambia quién tiene la sesión y
/// qué filas se siembran.
library;

/// Una persona de las pruebas.
class TestPerson {
  const TestPerson(this.id, this.name, {this.program, this.institution});

  final String id;
  final String name;
  final String? program;
  final String? institution;

  /// Su fila de la tabla `profile`.
  Map<String, dynamic> get profileRow => {
    '_owner': id,
    'name': name,
    'career': {
      'program': program ?? 'Ingeniería de Sistemas',
      'institution': institution ?? 'Universidad del Norte',
    },
    'description': 'Perfil de prueba de $name.',
    'skills': ['Flutter', 'Dart'],
    'profilePicture': '',
  };
}

abstract class Seed {
  // ─── Personas ─────────────────────────────────────────────────────────────
  /// Lidera el proyecto de las pruebas.
  static const laura = TestPerson('user-laura', 'Laura Líder');

  /// Quien postula en el flujo de descubrimiento.
  static const ana = TestPerson('user-ana', 'Ana Torres');

  /// Quien ya postuló cuando empiezan los flujos de aceptar y rechazar.
  static const bruno = TestPerson('user-bruno', 'Bruno Díaz');

  static const people = [laura, ana, bruno];

  /// Los perfiles de todas, por `user_id`.
  static Map<String, Map<String, dynamic>> get profiles => {
    for (final p in people) p.id: p.profileRow,
  };

  // ─── Proyecto ─────────────────────────────────────────────────────────────
  static const projectId = 'proj-huerta';
  static const projectTitle = 'Huerta urbana inteligente';

  /// Una dirección que nunca responde: las imágenes de prueba no deben salir a
  /// internet ni a ningún servidor. La app muestra su ícono de «imagen rota».
  static const unreachableImage = 'http://127.0.0.1:1/portada.png';

  /// El proyecto, creado por [owner].
  static Map<String, dynamic> project({String owner = 'user-laura'}) => {
    '_id': projectId,
    '_owner': owner,
    'title': projectTitle,
    'imageUrl': unreachableImage,
    'description': 'Huertas en azoteas con sensores de riego.',
    'jobs': ['Ing. de Sistemas', 'Ing. Ambiental'],
    'skills': ['Flutter', 'IoT'],
    'status': 'open',
    'progress': 0,
  };

  /// La fila de `project_member` de quien creó el proyecto.
  static Map<String, dynamic> ownerMembership({String userId = 'user-laura'}) =>
      {
        '_id': 'member-$userId',
        'project_id': projectId,
        'user_id': userId,
        'role': {'name': 'owner'},
        'status': 'active',
        'joinedAt': '2026-01-01T00:00:00.000Z',
      };

  /// Una solicitud pendiente de [userId] al proyecto.
  static Map<String, dynamic> pendingRequest({
    String id = 'solicitud-bruno',
    String userId = 'user-bruno',
  }) => {
    '_id': id,
    '_owner': userId,
    'user_id': userId,
    'project_id': projectId,
    'status': {'state': 'pending'},
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  // ─── Tareas ───────────────────────────────────────────────────────────────
  /// La fila de `project_member` donde se cuentan las tareas de [userId].
  static Map<String, dynamic> taskStay({
    String userId = 'user-laura',
    int taken = 0,
    int finished = 0,
  }) => {
    '_id': 'estancia-$userId',
    'project_id': projectId,
    'user_id': userId,
    'status': 'active',
    'joinedAt': '2026-01-01T00:00:00.000Z',
    'tasks_taken': taken,
    'tasks_finished': finished,
  };

  /// Una tarea del proyecto. [assignee] vacío es una tarea sin reservar.
  static Map<String, dynamic> task({
    required String id,
    required String title,
    String status = 'todo',
    String? assignee,
    List<Map<String, dynamic>> checklist = const [],
  }) => {
    '_id': id,
    '_owner': 'user-laura',
    'project_id': projectId,
    'title': title,
    'description': '',
    'status': status,
    'assignee_id': assignee,
    'checklist': checklist,
  };

  /// Un ítem del checklist.
  static Map<String, dynamic> item(String title, {bool done = false}) => {
    'title': title,
    'done': done,
  };
}
