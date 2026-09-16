import 'package:flutter/material.dart';

import 'package:f_clean_template/features/discover/domain/models/project.dart';

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
                  const SizedBox(width: 8),
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
                  Text('${project.members.length} miembros', style: tt.bodySmall),
                  const Spacer(),
                  ?trailing,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
