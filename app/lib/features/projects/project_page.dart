import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../discover/domain/models/project.dart';
import 'ui/viewmodels/user_projects_controller.dart';
import 'ui/views/collaboration_requests_page.dart';

/// Pestaña "Proyectos": muestra los proyectos que el usuario co-crea y los
/// que guardó desde Descubrir (pantalla "Collab-Saved" del flujo de Figma).
class ProjectPage extends StatelessWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserProjectsController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ColoredBox(
      color: cs.primaryContainer,
      child: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(title: 'Proyectos Co-creados', icon: Icons.add),
              if (controller.coCreatedProjects.isEmpty)
                _EmptyState(text: 'Aún no co-creas ningún proyecto.', tt: tt)
              else
                ...controller.coCreatedProjects.map(
                  (project) => _ProjectTile(
                    project: project,
                    trailing: _RequestsButton(
                      count: controller.pendingApplicantsCount(project.id),
                      onTap: () {
                        Get.to(
                          () => CollaborationRequestsPage(project: project),
                        );
                      },
                      cs: cs,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Proyectos guardados',
                icon: Icons.bookmark_outline,
              ),
              if (controller.savedProjects.isEmpty)
                _EmptyState(
                  text: 'Guarda proyectos desde Descubrir para verlos aquí.',
                  tt: tt,
                )
              else
                ...controller.savedProjects.map(
                  (project) => _ProjectTile(
                    project: project,
                    trailing: _ApplyButton(
                      applied: controller.isApplied(project.id),
                      onApply: () => controller.applyToProject(project),
                      cs: cs,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Icon(icon, color: cs.onPrimaryContainer),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  final TextTheme tt;

  const _EmptyState({required this.text, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: tt.bodyMedium),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  final Widget trailing;

  const _ProjectTile({required this.project, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                project.status,
                style: tt.labelMedium?.copyWith(color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${project.members.length} miembros',
                style: tt.bodySmall,
              ),
              const Spacer(),
              trailing,
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestsButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _RequestsButton({
    required this.count,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: cs.secondaryContainer),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline, size: 16, color: cs.onSecondaryContainer),
            const SizedBox(width: 4),
            Text(
              '$count solicitud${count == 1 ? '' : 'es'}',
              style: TextStyle(color: cs.onSecondaryContainer, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final bool applied;
  final VoidCallback onApply;
  final ColorScheme cs;

  const _ApplyButton({
    required this.applied,
    required this.onApply,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: applied ? null : onApply,
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(applied ? 'Aplicado' : 'Aplicar'),
    );
  }
}
