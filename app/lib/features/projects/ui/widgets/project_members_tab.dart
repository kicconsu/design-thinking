import 'package:flutter/material.dart';

import 'package:imker/core/widgets/profile_avatar.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';

/// Pestaña "Miembros" de la información del proyecto: quién está en el
/// proyecto, con su carrera, su papel y desde cuándo.
class ProjectMembersTab extends StatelessWidget {
  const ProjectMembersTab({
    super.key,
    required this.members,
    required this.isLoading,
    required this.loaded,
    required this.isMe,
    this.error,
    this.onRetry,
  });

  final List<ProjectMember> members;
  final bool isLoading;

  /// Si ya hubo un primer intento de carga.
  final bool loaded;
  final bool Function(ProjectMember member) isMe;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (members.isEmpty) {
      if (isLoading || !loaded) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              error ?? 'Aún no hay miembros en este proyecto.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium,
            ),
            if (error != null && onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          members.length == 1 ? '1 miembro' : '${members.length} miembros',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Con una recarga fallida se sigue viendo la lista anterior.
        if (error != null) ...[
          Text(
            error!,
            style: tt.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
        ],
        for (final member in members)
          _MemberTile(member: member, isMe: isMe(member)),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isMe});

  final ProjectMember member;
  final bool isMe;

  static const _months = [
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

  String? get _since {
    final d = member.joinedAt?.toLocal();
    if (d == null) return null;
    return 'Desde ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final since = _since;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          ProfileAvatar(name: member.name, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${member.name} (Tú)' : member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (member.career.isNotEmpty)
                  Text(
                    member.career,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall,
                  ),
                if (since != null)
                  Text(
                    since,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoleBadge(role: member.role),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

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
