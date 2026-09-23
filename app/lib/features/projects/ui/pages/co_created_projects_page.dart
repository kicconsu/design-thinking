import 'package:imker/features/projects/ui/views/collaboration_requests_page.dart';
import 'package:imker/features/projects/ui/views/create_project.dart';
import 'package:imker/features/projects/ui/views/requests_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';

/// Vista para los proyectos que el usuario co-crea.
/// Nota: El detalle de proyecto existente está reservado para otras categorías.
class CoCreatedProjectsPage extends StatelessWidget {
  const CoCreatedProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserProjectsController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => controller.fetchCoCreatedProjects(),
      child: Obx(() {
        if (controller.isLoadingProjects.value && controller.coCreatedProjects.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final projects = controller.coCreatedProjects;

        if (projects.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: 120),
              Center(
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
              ),
            ],
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
                  onPressed: () => Get.to(() => const CreateProjectPage()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...projects.map(
              (project) => ProjectTile(
                project: project,
                trailing: RequestsButton(
                  count: project.applicantsCount,
                  onTap: () => Get.to(() => CollaborationRequestsPage(project: project)),
                  cs: cs,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

