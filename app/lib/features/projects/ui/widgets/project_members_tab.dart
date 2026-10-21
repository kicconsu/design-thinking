import 'package:flutter/material.dart';

import 'package:imker/core/widgets/profile_avatar.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';
import 'package:imker/features/projects/ui/widgets/member_labels.dart';

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
    this.onOpenMember,
    this.canManage = false,
  });

  final List<ProjectMember> members;
  final bool isLoading;

  /// Si ya hubo un primer intento de carga.
  final bool loaded;
  final bool Function(ProjectMember member) isMe;
  final String? error;
  final VoidCallback? onRetry;

  /// Abre la ficha de un miembro al tocar su tarjeta.
  final ValueChanged<ProjectMember>? onOpenMember;

  /// Quien mira puede quitar a otros (es el creador): solo cambia la pista.
  final bool canManage;

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
        if (onOpenMember != null) ...[
          const SizedBox(height: 2),
          Text(
            canManage
                ? 'Toca a alguien para ver su ficha o quitarlo del proyecto.'
                : 'Toca a alguien para ver su perfil.',
            style: tt.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
          _MemberTile(
            member: member,
            isMe: isMe(member),
            onTap: onOpenMember == null ? null : () => onOpenMember!(member),
          ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isMe, this.onTap});

  final ProjectMember member;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final since = memberSinceLabel(member.joinedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        shape: Border.all(color: cs.outline),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ProjectRoleBadge(role: member.role),
                if (onTap != null)
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
