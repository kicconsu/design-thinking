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
      ),
      const Project(
        id: '2',
        title: 'AquaNet: Monitoreo inteligente de recursos hídricos',
        imageUrl: 'https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fi.pinimg.com%2Foriginals%2F38%2Ff3%2F64%2F38f364f4f3f233ccd92b754a609e6e8f.jpg&f=1&nofb=1&ipt=bcaf6ada0543ef86cc415c92635b02e4039ee55ff474a26c09cb8a9008adc780',
        jobs: ['Ing. Ambiental', 'Data Scientist', 'Ing. Civil'],
        skills: ['IoT', 'Machine Learning', 'Gestión hídrica', 'Python'],
        description: 'Sistema de monitoreo en tiempo real para cuencas hidrográficas urbanas. Combinamos sensores IoT con modelos predictivos para anticipar eventos de escasez o inundación.',
      ),
      const Project(
        id: '3',
        title: 'EduReach: Plataforma de educación rural descentralizada',
        imageUrl: 'https://external-content.duckduckgo.com/iu/?u=http%3A%2F%2F2.bp.blogspot.com%2F-6HbxqEi9Qi8%2FTxnVvVlV8jI%2FAAAAAAAAutI%2F_Z1ePN7hy5I%2Fs1600%2Fhermosa-foca-marina-sea-animals.jpg&f=1&nofb=1&ipt=7f45e193e4727639880dc3d895a15c8310e140fe5336b0f8a8c523ba277356c1',
        jobs: ['Ing. Software', 'Diseñador UX', 'Pedagogo'],
        skills: [
          'Flutter',
          'Diseño instruccional',
          'Offline-first',
          'Accesibilidad',
        ],
        description: 'Aplicación móvil para comunidades rurales con conectividad intermitente. Permite acceso a contenido educativo sincronizado, con énfasis en lenguas originarias y contextos locales.',
      ),
    ]);
  }
}
