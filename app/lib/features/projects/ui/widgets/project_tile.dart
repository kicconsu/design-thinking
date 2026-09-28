import 'package:flutter/material.dart';

import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_status.dart';
import 'package:imker/features/projects/ui/widgets/project_status_label.dart';

/// Tarjeta reutilizable para mostrar un proyecto en las listas de proyectos.
class ProjectTile extends StatelessWidget {
  final Project project;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProjectTile({
    super.key,
    required this.project,
    this.trailing,
    this.onTap,
  });

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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${project.members.length} miembros',
                    style: tt.bodySmall,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: ProjectStatusLabel(
                            status: ProjectStatus.fromName(project.status),
                          ),
                        ),
                        if (trailing != null) const SizedBox(width: 8),
                        ?trailing,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
