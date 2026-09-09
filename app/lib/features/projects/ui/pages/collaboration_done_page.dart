import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../home/ui/viewmodels/home_view_model.dart';
import '../../../discover/domain/models/project.dart';
import '../viewmodels/user_projects_controller.dart';

/// Pantalla "Done!" del flujo de Figma: confirma la postulación del usuario
/// para colaborar en el proyecto.
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
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Imker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Listo!',
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Center(
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: cs.tertiaryContainer,
                  child: Icon(
                    Icons.emoji_people_outlined,
                    size: 64,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'La información de tu perfil (CV, datos personales, habilidades) '
                'será enviada al líder del proyecto para ser verificada.',
                textAlign: TextAlign.center,
                style: tt.bodyLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  Get.find<HomeViewModel>().changePage(1);
                  Get.until((route) => route.isFirst);
                },
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Ver proyectos pendientes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
