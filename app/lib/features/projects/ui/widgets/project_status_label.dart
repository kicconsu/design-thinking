import 'package:flutter/material.dart';

import 'package:imker/features/projects/domain/models/project_status.dart';

/// Estado del proyecto como metadato tranquilo (punto de color + texto),
/// pensado para convivir con el conteo de miembros sin comerle espacio
/// al título.
class ProjectStatusLabel extends StatelessWidget {
  const ProjectStatusLabel({super.key, required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOpen = status == ProjectStatus.open;
    final color = isOpen ? cs.primary : cs.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          status.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isOpen ? cs.primary : cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
