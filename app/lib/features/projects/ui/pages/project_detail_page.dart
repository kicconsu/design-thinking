import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/features/discover/domain/models/project.dart';
import 'package:f_clean_template/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:f_clean_template/features/projects/ui/widgets/confirm_application_dialog.dart';

/// Pantalla de detalle de proyecto: permite ver la descripción completa,
/// integrantes, habilidades requeridas y postularse al proyecto.
class ProjectDetailPage extends StatelessWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userProjectsController = Get.find<UserProjectsController>();

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Imker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(project.title, style: tt.headlineSmall),
            const SizedBox(height: 20),
            _Section(
              title: 'Descripción',
              child: Text(project.description, style: tt.bodyMedium),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Integrantes',
              child: project.members.isEmpty
                  ? Text(
                      'Aún no hay integrantes definidos.',
                      style: tt.bodyMedium,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: project.members
                          .map((m) => Text('• $m', style: tt.bodyMedium))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Habilidades',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscamos personas con las siguientes habilidades:',
                    style: tt.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  ...project.skills.map(
                    (s) => Text('• $s', style: tt.bodyMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Obx(() {
              final isPending = userProjectsController.isApplied(project.id);
              final isActive = userProjectsController.activeProjects
                  .any((p) => p.id == project.id);

              // No mostrar el botón si ya es pendiente o colaboración activa
              if (isPending || isActive) return const SizedBox.shrink();

              return FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () => showConfirmApplicationDialog(
                  context: context,
                  project: project,
                ),
                icon: const Icon(Icons.volunteer_activism_outlined),
                label: const Text('¡Quiero colaborar!'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Divider(color: cs.outline),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
