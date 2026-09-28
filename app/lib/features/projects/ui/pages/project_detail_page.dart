import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/widgets/account_required_prompt.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/widgets/confirm_application_dialog.dart';

/// Pantalla de detalle de proyecto: permite ver la descripción completa,
/// integrantes, habilidades requeridas y postularse al proyecto.
class ProjectDetailPage extends StatelessWidget {
  final Project? project;

  const ProjectDetailPage({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    final effectiveProject =
        project ?? (Get.arguments is Project ? Get.arguments as Project : null);
    if (effectiveProject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proyecto')),
        body: const Center(child: Text('No se especificó un proyecto')),
      );
    }
    final projectItem = effectiveProject;
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
            Text(projectItem.title, style: tt.headlineSmall),
            if (projectItem.imageUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _ProjectCover(url: projectItem.imageUrl),
            ],
            const SizedBox(height: 20),
            _Section(
              title: 'Descripción',
              child: Text(projectItem.description, style: tt.bodyMedium),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Integrantes',
              child: projectItem.members.isEmpty
                  ? Text(
                      'Aún no hay integrantes definidos.',
                      style: tt.bodyMedium,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: projectItem.members
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
                  ...projectItem.skills.map(
                    (s) => Text('• $s', style: tt.bodyMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Obx(() {
              final isOwner = userProjectsController.isOwner(projectItem);
              final isPending = userProjectsController.isApplied(
                projectItem.id,
              );
              final isActive = userProjectsController.activeProjects.any(
                (p) => p.id == projectItem.id,
              );

              if (isOwner) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    border: Border.all(color: cs.outline),
                  ),
                  child: Center(
                    child: Text(
                      'Eres el creador de este proyecto',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                );
              }

              // No mostrar el botón si ya es pendiente o colaboración activa
              if (isPending || isActive) return const SizedBox.shrink();

              return FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed:
                    (() => showConfirmApplicationDialog(
                      context: context,
                      project: projectItem,
                    )).guarded(
                      'Para postularte a un proyecto necesitas una cuenta real.',
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

/// Imagen de portada del proyecto entre el título y la descripción.
class _ProjectCover extends StatelessWidget {
  final String url;

  const _ProjectCover({required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
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
