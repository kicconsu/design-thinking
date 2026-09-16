import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/core/widgets/operation_done_page.dart';
import 'package:f_clean_template/features/discover/domain/models/project.dart';
import 'package:f_clean_template/features/projects/ui/viewmodels/user_projects_controller.dart';

/// Pantalla "Done!" del flujo de Figma: confirma la postulación del usuario
/// para colaborar en el proyecto usando el componente reutilizable OperationDonePage.
class CollaborationDonePage extends StatefulWidget {
  final Project project;

  const CollaborationDonePage({super.key, required this.project});

  @override
  State<CollaborationDonePage> createState() => _CollaborationDonePageState();
}

class _CollaborationDonePageState extends State<CollaborationDonePage> {
  @override
  void initState() {
    super.initState();
    // Se marca la postulación después de terminar el build actual: llamarlo
    // directo en initState dispara el Obx de la página anterior a mitad de
    // su propio build y Flutter lo rechaza con un error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<UserProjectsController>().applyToProject(widget.project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OperationDonePage(
      title: '¡Listo!',
      text:
          'La información de tu perfil (CV, datos personales, habilidades) '
          'será enviada al líder del proyecto para ser verificada.',
      image: Icon(
        Icons.emoji_people_outlined,
        size: 64,
        color: cs.onTertiaryContainer,
      ),
      buttonText: 'Volver',
      buttonIcon: Icons.arrow_back,
      onButtonPressed: () => Get.back(),
    );
  }
}
