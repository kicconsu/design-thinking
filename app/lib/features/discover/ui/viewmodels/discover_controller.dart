import 'package:f_clean_template/features/discover/domain/models/project.dart';
import 'package:get/get.dart';

class DiscoverController extends GetxController {
  final RxList<Project> projects = <Project>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadMockProjects();
  }

  void _loadMockProjects() {
    projects.assignAll([
      const Project(
        id: '1',
        title: 'Kirche: Proyecto de renovación urbana y sostenibilidad',
        imageUrl: 'https://fultoncountyvetclinic.com/wp-content/uploads/bb-plugin/cache/cat-stretching-panorama-fd4135722bc818a9db1debc7def411a0-4hg3jvxm67az.jpg',
        jobs: [
          'Ing. Software',
          'Ing. Ambiental',
          'Ing. Electrónica',
          'Ing. Industrial',
        ],
        skills: [
          'Modelación',
          'Análisis de datos',
          'Desarrollo de software',
          'Diseño de software',
        ],
        description: 'Proyecto de renovación urbana enfocado en la integración de tecnologías sostenibles en edificios históricos. Buscamos profesionales apasionados por el impacto social y la innovación tecnológica.',
        members: ['Pedro Jiménez', 'Alberto Mendoza', 'Juana De Arco'],
        status: 'En Desarrollo',
        applicantsCount: 2,
      ),
      const Project(
        id: '2',
        title: 'AquaNet: Monitoreo inteligente de recursos hídricos',
        imageUrl: 'https://picsum.photos/seed/aquanet-imker/800/450',
        jobs: ['Ing. Ambiental', 'Data Scientist', 'Ing. Civil'],
        skills: ['IoT', 'Machine Learning', 'Gestión hídrica', 'Python'],
        description: 'Sistema de monitoreo en tiempo real para cuencas hidrográficas urbanas. Combinamos sensores IoT con modelos predictivos para anticipar eventos de escasez o inundación.',
        members: ['Camila Restrepo', 'Julián Ortiz'],
        status: 'En Desarrollo',
        applicantsCount: 1,
      ),
      const Project(
        id: '3',
        title: 'EduReach: Plataforma de educación rural descentralizada',
        imageUrl: 'https://picsum.photos/seed/edureach-imker/800/450',
        jobs: ['Ing. Software', 'Diseñador UX', 'Pedagogo'],
        skills: [
          'Flutter',
          'Diseño instruccional',
          'Offline-first',
          'Accesibilidad',
        ],
        description: 'Aplicación móvil para comunidades rurales con conectividad intermitente. Permite acceso a contenido educativo sincronizado, con énfasis en lenguas originarias y contextos locales.',
        members: ['Laura Gómez'],
        status: 'En Desarrollo',
        applicantsCount: 0,
      ),
    ]);
  }
}
