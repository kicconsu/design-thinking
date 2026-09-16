import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:f_clean_template/features/projects/ui/widgets/project_tile.dart';

/// Vista para los proyectos que el usuario co-crea.
/// Nota: El detalle de proyecto existente está reservado para otras categorías.
class CoCreatedProjectsPage extends StatelessWidget {
  const CoCreatedProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserProjectsController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Obx(() {
      final projects = controller.coCreatedProjects;

      if (projects.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.architecture_outlined,
                  size: 64,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aún no co-creas ningún proyecto.',
                  style: tt.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando crees o lideres iniciativas aparecerán aquí.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Proyectos Co-creados',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                tooltip: 'Crear nuevo proyecto',
                onPressed: () {
                  Get.snackbar(
                    'Crear proyecto',
                    'El flujo de creación estará disponible próximamente.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...projects.map(
            (project) => ProjectTile(
              project: project,
              // NO tiene onTap hacia ProjectDetailPage por requerimiento
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: cs.secondaryContainer),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_outline,
                      size: 16,
                      color: cs.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${project.applicantsCount} postulados',
                      style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
