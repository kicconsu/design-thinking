import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/projects/ui/pages/co_created_projects_page.dart';
import 'package:imker/features/projects/ui/pages/other_projects_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/widgets/projects_guest_gate.dart';
import 'package:imker/core/widgets/segmented_tab_switch.dart';

/// Página principal del feature Proyectos:
/// Coordina la alternancia entre "Proyectos Co-creados" y "Otros Proyectos"
/// mediante un selector segmented tipo píldora inspirado en el diseño Imker.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthenticationController>();
    final controller = Get.find<UserProjectsController>();
    final cs = Theme.of(context).colorScheme;

    return ColoredBox(
      color: cs.primaryContainer,
      child: SafeArea(
        child: Obx(() {
          if (auth.isAnonymous) {
            return const ProjectsGuestGate();
          }

          return Column(
            children: [
              // Selector segmented de pestañas principales (estilo imagen adjunta)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Obx(() {
                  final coCreatedCount = controller.coCreatedProjects.length;
                  final othersCount = controller.savedProjects.length +
                      controller.activeProjects.length;

                  return SegmentedTabSwitch(
                    selectedIndex: controller.selectedMainTab.value,
                    tabs: [
                      'Co-creados ($coCreatedCount)',
                      'Otros proyectos ($othersCount)',
                    ],
                    onTabSelected: (index) {
                      controller.selectedMainTab.value = index;
                    },
                  );
                }),
              ),

              // Contenido alternable
              Expanded(
                child: Obx(() {
                  final selectedTab = controller.selectedMainTab.value;
                  return IndexedStack(
                    index: selectedTab,
                    children: const [
                      CoCreatedProjectsPage(),
                      OtherProjectsPage(),
                    ],
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}
