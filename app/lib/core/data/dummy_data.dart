import 'package:imker/features/projects/domain/models/project.dart';

/// El backend falso: las mismas filas que devolvería Roble, en memoria.
///
/// Guarda **filas** (Maps con _id, _owner, etc.) y no solo entidades, para que
/// los datasources en memoria devuelvan exactamente la misma estructura que Roble.
/// Así, el repositorio ejecuta la misma lógica de mapeo y validación tanto en
/// desarrollo local/pruebas como con el backend real.
class DummyData {
  DummyData() {
    _seed();
  }

  /// Instancia única compartida por defecto si no se inyecta otra.
  static final DummyData instance = DummyData();

  // ─── Identificadores Canónicos ───────────────────────────────────────────
  static const String kircheId = '1';
  static const String aquaNetId = '2';
  static const String eduReachId = '3';
  static const String solariaId = 'solaria-active';

  // ─── Credenciales de Prueba (Desarrollo) ───────────────────────────────────
  static const String devEmail = 'dev@uninorte.edu.co';
  static const String devPassword = 'ThePassword1!';

  /// Filas de la tabla 'project' que devolvería Roble.
  /// Respeta la convención de almacenar listas bajo {"values": [...]}.
  final projects = <Map<String, dynamic>>[];

  // ─── Entidades estáticas para vistas que aún no tienen backend ───────────
  static const Project kircheProject = Project(
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

  static const Project solariaProject = Project(
    id: solariaId,
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

  void _seed() {
    projects.addAll([
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
    ]);
  }
}
