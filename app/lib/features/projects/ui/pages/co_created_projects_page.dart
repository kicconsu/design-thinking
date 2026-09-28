import 'package:imker/features/projects/ui/views/collaboration_requests_page.dart';
import 'package:imker/features/projects/ui/views/create_project.dart';
import 'package:imker/features/projects/ui/views/requests_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';

/// Vista de "Mis proyectos": los proyectos que el usuario crea y lidera.
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
        if (controller.isLoadingProjects.value &&
            controller.coCreatedProjects.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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
                        'Aún no tienes proyectos propios.',
                        style: tt.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea uno y desde ahí invitarás a quienes quieras colaborar.',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () =>
                            Get.to(() => const CreateProjectPage()),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear mi primer proyecto'),
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
              children: [
                Expanded(
                  child: Text(
                    'Mis proyectos',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Crear proyecto',
                  child: FilledButton.icon(
                    onPressed: () => Get.to(() => const CreateProjectPage()),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...projects.map(
              (project) => ProjectTile(
                project: project,
                trailing: RequestsButton(
                  count: controller.pendingApplicantsCount(project.id),
                  onTap: () =>
                      Get.to(() => CollaborationRequestsPage(project: project)),
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
