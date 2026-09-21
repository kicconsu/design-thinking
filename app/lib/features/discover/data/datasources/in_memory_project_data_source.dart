import 'i_project_data_source.dart';

/// Backend falso: sirve las mismas filas que devolvería Roble.
/// Útil para desarrollo sin red y para pruebas unitarias del repositorio.
class InMemoryProjectDataSource implements IProjectDataSource {
  static final List<Map<String, dynamic>> _data = [
    {
      '_id': '1',
      '_owner': 'demo-owner',
      'title': 'Kirche: Proyecto de renovación urbana y sostenibilidad',
      'imageUrl': 'https://picsum.photos/seed/kirche-imker/800/450',
      'description':
          'Proyecto de renovación urbana enfocado en la integración de tecnologías sostenibles en edificios históricos.',
      'jobs': ['Ing. Software', 'Ing. Ambiental', 'Ing. Electrónica', 'Ing. Industrial'],
      'skills': ['Modelación', 'Análisis de datos', 'Desarrollo de software', 'Diseño de software'],
      'status': 'open',
    },
    {
      '_id': '2',
      '_owner': 'demo-owner',
      'title': 'AquaNet: Monitoreo inteligente de recursos hídricos',
      'imageUrl': 'https://picsum.photos/seed/aquanet-imker/800/450',
      'description':
          'Sistema de monitoreo en tiempo real para cuencas hidrográficas urbanas. Combinamos sensores IoT con modelos predictivos.',
      'jobs': ['Ing. Ambiental', 'Data Scientist', 'Ing. Civil'],
      'skills': ['IoT', 'Machine Learning', 'Gestión hídrica', 'Python'],
      'status': 'open',
    },
    {
      '_id': '3',
      '_owner': 'demo-owner',
      'title': 'EduReach: Plataforma de educación rural descentralizada',
      'imageUrl': 'https://picsum.photos/seed/edureach-imker/800/450',
      'description':
          'Aplicación móvil para comunidades rurales con conectividad intermitente.',
      'jobs': ['Ing. Software', 'Diseñador UX', 'Pedagogo'],
      'skills': ['Flutter', 'Diseño instruccional', 'Offline-first', 'Accesibilidad'],
      'status': 'open',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> readProjects() async => _data;

  @override
  Future<Map<String, dynamic>?> readProjectById(String id) async =>
      _data.where((r) => r['_id'] == id).firstOrNull;
}
