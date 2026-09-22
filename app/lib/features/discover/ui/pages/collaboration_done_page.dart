import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/operation_done_page.dart';
import 'package:imker/features/projects/domain/models/project.dart';

/// Pantalla "Done!" del flujo de Figma: confirma la postulación del usuario
/// para colaborar en el proyecto usando el componente reutilizable OperationDonePage.
class CollaborationDonePage extends StatelessWidget {
  final Project project;

  const CollaborationDonePage({super.key, required this.project});

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
