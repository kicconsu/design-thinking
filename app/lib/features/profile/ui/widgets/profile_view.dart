import 'package:flutter/material.dart';

import 'package:imker/core/widgets/profile_avatar.dart';
import 'package:imker/core/widgets/trust_indicators.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';

import '../../domain/models/user_profile.dart';

/// Presentación de un perfil: lo que verá otra persona al abrirlo.
///
/// Solo recibe datos y callbacks (no conoce GetX), así que sirve igual para el
/// perfil propio y, más adelante, para el de otra persona ([isOwn] = false).
class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.name,
    required this.profile,
    this.isOwn = false,
    this.projects = const [],
    this.onOpenSettings,
    this.onEdit,
    this.onOpenProject,
    this.onOpenProjects,
    this.onOpenIndicators,
    this.onOpenHistory,
  });

  final String name;
  final UserProfile profile;
  final bool isOwn;
  final List<Project> projects;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onEdit;
  final ValueChanged<Project>? onOpenProject;
  final VoidCallback? onOpenProjects;
  final VoidCallback? onOpenIndicators;
  final VoidCallback? onOpenHistory;

  static const _previewCount = 2;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          name: name,
          profile: profile,
          projectCount: projects.length,
          isOwn: isOwn,
          onOpenSettings: onOpenSettings,
          onEdit: onEdit,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Sobre ti',
          child: Text(
            profile.bio.isNotEmpty
                ? profile.bio
                : (isOwn
                      ? 'Aún no has escrito nada sobre ti.'
                      : 'Aún no escribió nada.'),
            style: tt.bodyMedium?.copyWith(
              color: profile.bio.isEmpty ? cs.onSurfaceVariant : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Habilidades',
          child: profile.skills.isEmpty
              ? Text(
                  isOwn
                      ? 'Aún no agregas habilidades.'
                      : 'Aún no agrega habilidades.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in profile.skills)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          border: Border.all(color: cs.outline),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(color: cs.onSecondaryContainer),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Proyectos',
          onTap: onOpenProjects,
          actionLabel: projects.length > _previewCount
              ? 'Ver todos (${projects.length})'
              : null,
          child: projects.isEmpty
              ? Text(
                  isOwn
                      ? 'Todavía no participas en ningún proyecto.'
                      : 'Todavía no participa en ningún proyecto.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                )
              : Column(
                  children: [
                    for (final p in projects.take(_previewCount))
                      ProjectTile(
                        project: p,
                        onTap: onOpenProject == null
                            ? null
                            : () => onOpenProject!(p),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Indicadores de confianza',
          onTap: onOpenIndicators,
          child: profile.hasTrustHistory
              ? TrustIndicators(
                  commitmentScore: profile.commitmentScore,
                  onTimeScore: profile.onTimeScore,
                  responseRateScore: profile.responseRateScore,
                  completedProjectsScore: profile.completedProjectsScore,
                  showTitle: false,
                )
              : Text(
                  'Aparecerán cuando ${isOwn ? 'colabores' : 'colabore'} en proyectos.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
        ),
        const SizedBox(height: 12),
        _NavRow(
          icon: Icons.history,
          label: 'Historial de colaboración',
          onTap: onOpenHistory,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.profile,
    required this.projectCount,
    required this.isOwn,
    this.onOpenSettings,
    this.onEdit,
  });

  final String name;
  final UserProfile profile;
  final int projectCount;
  final bool isOwn;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final summary = [
      '$projectCount ${projectCount == 1 ? 'proyecto' : 'proyectos'}',
      '${profile.skills.length} ${profile.skills.length == 1 ? 'habilidad' : 'habilidades'}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(name: name, radius: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.academicInfo.isNotEmpty
                          ? profile.academicInfo
                          : (isOwn
                                ? 'Agrega tu carrera'
                                : 'Sin carrera indicada'),
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwn && onOpenSettings != null)
                IconButton(
                  tooltip: 'Ajustes',
                  icon: Icon(
                    Icons.settings_outlined,
                    color: cs.onTertiaryContainer,
                  ),
                  onPressed: onOpenSettings,
                ),
            ],
          ),
          if (isOwn && onEdit != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: onEdit,
                child: const Text('Editar perfil'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta con título; si recibe [onTap] se puede abrir (muestra un chevron).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.onTap,
    this.actionLabel,
  });

  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (actionLabel != null)
                    Text(
                      actionLabel!,
                      style: tt.bodySmall?.copyWith(color: cs.primary),
                    ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
