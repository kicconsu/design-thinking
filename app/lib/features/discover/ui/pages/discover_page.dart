import 'package:f_clean_template/features/discover/ui/viewmodels/discover_controller.dart';
import 'package:f_clean_template/features/projects/ui/widgets/project_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    //Se crea la primera vez que DiscoverPage se construye y GetX lo destruye cuando ya no haya referencias.
    final controller = Get.put(DiscoverController());

    return Obx(() {
      if (controller.projects.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return PageView.builder(
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
      );
    });
  }
}
