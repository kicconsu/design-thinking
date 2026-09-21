import 'package:imker/features/projects/domain/models/project.dart';

/// Datos de muestra compartidos entre el datasource en memoria y
/// el controlador de proyectos del usuario.
///
/// Centralizar aquí evita que distintas partes de la app usen IDs o URLs
/// diferentes para el mismo proyecto conceptual, lo que rompería la
/// coherencia entre el feed de Discover y la pestaña de Proyectos.
abstract class ProjectFixtures {
  // ─── Proyectos del feed (Discover) ────────────────────────────────────────
  // Estos son los que devuelve InMemoryProjectDataSource y sirven como fuente
  // de verdad para toda la app en modo desarrollo.

  static const String kircheId = '1';
  static const String aquaNetId = '2';
  static const String eduReachId = '3';

  /// Filas en el formato exacto que devuelve Roble (con _id, _owner, etc.).
  /// Los campos de tipo lista SIEMPRE usan la forma {"values": [...]}.
  /// El repositorio las mapea a entidades [Project].
  static final List<Map<String, dynamic>> rows = [
    {
      '_id': kircheId,
      '_owner': 'demo-owner',
      'title': 'Kirche: Proyecto de renovación urbana y sostenibilidad',
      'imageUrl': 'https://picsum.photos/seed/kirche-imker/800/450',
      'description':
          'Proyecto de renovación urbana enfocado en la integración de tecnologías sostenibles en edificios históricos.',
      'jobs': {
        'values': ['Ing. Software', 'Ing. Ambiental', 'Ing. Electrónica', 'Ing. Industrial'],
      },
      'skills': {
        'values': ['Modelación', 'Análisis de datos', 'Desarrollo de software', 'Diseño de software'],
      },
      'status': 'open',
    },
    {
      '_id': aquaNetId,
      '_owner': 'demo-owner',
      'title': 'AquaNet: Monitoreo inteligente de recursos hídricos',
      'imageUrl': 'https://picsum.photos/seed/aquanet-imker/800/450',
      'description':
          'Sistema de monitoreo en tiempo real para cuencas hidrográficas urbanas. Combinamos sensores IoT con modelos predictivos.',
      'jobs': {
        'values': ['Ing. Ambiental', 'Data Scientist', 'Ing. Civil'],
      },
      'skills': {
        'values': ['IoT', 'Machine Learning', 'Gestión hídrica', 'Python'],
      },
      'status': 'open',
    },
    {
      '_id': eduReachId,
      '_owner': 'demo-owner',
      'title': 'EduReach: Plataforma de educación rural descentralizada',
      'imageUrl': 'https://picsum.photos/seed/edureach-imker/800/450',
      'description':
          'Aplicación móvil para comunidades rurales con conectividad intermitente.',
      'jobs': {
        'values': ['Ing. Software', 'Diseñador UX', 'Pedagogo'],
      },
      'skills': {
        'values': ['Flutter', 'Diseño instruccional', 'Offline-first', 'Accesibilidad'],
      },
      'status': 'open',
    },
  ];

  // ─── Entidades [Project] listas para usar en controllers ─────────────────
  // Se usan en UserProjectsController para los proyectos co-creados y activos.

  static const Project kirche = Project(
    id: kircheId,
    owner: 'demo-owner',
    title: 'Kirche: Proyecto de renovación urbana y sostenibilidad',
    imageUrl: 'https://picsum.photos/seed/kirche-imker/800/450',
    description:
        'Proyecto de renovación urbana enfocado en la integración de tecnologías sostenibles en edificios históricos.',
    jobs: ['Ing. Software', 'Ing. Ambiental', 'Ing. Electrónica', 'Ing. Industrial'],
    skills: ['Modelación', 'Análisis de datos', 'Desarrollo de software', 'Diseño de software'],
    members: ['Pedro Jiménez', 'Alberto Mendoza', 'Juana De Arco'],
    status: 'open',
    applicantsCount: 1,
  );

  static const Project solaria = Project(
    id: 'solaria-active',
    owner: 'demo-owner',
    title: 'Solaria: Red comunitaria de microrredes solares',
    imageUrl: 'https://picsum.photos/seed/solaria-panel/800/450',
    description:
        'Implementación de microrredes solares conectadas entre vecinos para compartir excedentes de energía limpia.',
    jobs: ['Ing. Eléctrica', 'Desarrollador IoT'],
    skills: ['Hardware', 'Firmware', 'C++', 'Sistemas Embebidos'],
    members: ['Santiago Vargas', 'Tú (Colaborador)', 'Mariana Ruiz'],
    status: 'open',
    applicantsCount: 5,
  );
}
