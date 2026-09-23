import 'i_profile_data_source.dart';

/// Backend falso: una sola fila de perfil en memoria, igual de forma a la
/// que devolvería Roble. Útil para desarrollo sin red.
///
/// Se siembra con el mismo contenido de ejemplo usado en el prototipo de
/// Figma (Valentina Ríos) para poder probar la pantalla de una vez.
class InMemoryProfileDataSource implements IProfileDataSource {
  final Map<String, dynamic> _row = {
    '_id': 'demo-profile',
    '_owner': 'demo-owner',
    'name': 'Valentina Ríos',
    'career': {
      'program': 'Ingeniería de Sistemas',
      'institution': 'Universidad de la Costa',
    },
    'description':
        'Especializada en análisis y minería de datos. Me gustan los proyectos con impacto real. He contribuido a dos startups universitarias como consultora.',
    'skills': ['Python', 'Jupyter', 'PowerBI', 'SQL', 'R'],
    'profilePicture': '',
  };

  @override
  Future<Map<String, dynamic>?> readMyProfile() async => _row;

  @override
  Future<Map<String, dynamic>> updateMyProfile({
    required String bio,
    required List<String> skills,
  }) async {
    _row['description'] = bio;
    _row['skills'] = skills;
    return _row;
  }
}
