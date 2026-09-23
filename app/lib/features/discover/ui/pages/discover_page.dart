import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imker/features/discover/ui/widgets/filter_bar.dart';

import '../viewmodels/discover_controller.dart';
import '../widgets/project_card.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DiscoverController>();

    return Obx(() {
      if (controller.isLoading.value && controller.projects.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.value != null && controller.projects.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  controller.error.value!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.loadProjects,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.projects.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No hay proyectos disponibles por el momento.'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: controller.loadProjects,
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadProjects,
        child: Column(
          children: [
            FilterBar(controller: controller),
            Expanded(
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                controller: PageController(viewportFraction: 0.92),
                itemCount: controller.projects.length,
                itemBuilder: (context, index) {
                  final project = controller.projects[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ProjectCard(project: project),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
