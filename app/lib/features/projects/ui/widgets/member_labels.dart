import 'package:flutter/material.dart';

import 'package:imker/features/projects/domain/models/project_member.dart';

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// «Desde 3 oct 2026»; null si no se sabe cuándo entró.
String? memberSinceLabel(DateTime? joinedAt) {
  final d = joinedAt?.toLocal();
  if (d == null) return null;
  return 'Desde ${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Etiqueta del papel de una persona en el proyecto (Creador o Colaborador).
class ProjectRoleBadge extends StatelessWidget {
  const ProjectRoleBadge({super.key, required this.role});

  final ProjectMemberRole role;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final owner = role == ProjectMemberRole.owner;
    final background = owner ? cs.tertiaryContainer : cs.secondaryContainer;
    final foreground = owner ? cs.onTertiaryContainer : cs.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: cs.outline),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
