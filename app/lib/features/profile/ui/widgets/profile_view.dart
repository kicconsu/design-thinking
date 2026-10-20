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
    this.projects,
    this.onOpenSettings,
    this.onComplete,
    this.onOpenProject,
    this.onOpenIndicators,
    this.onOpenHistory,
    this.trustLoading = false,
    this.trustError,
    this.onRetryTrust,
  });

  final String name;
  final UserProfile profile;
  final bool isOwn;

  /// Proyectos de la persona; `null` si no se conocen (el perfil de otra
  /// persona): entonces no se muestran la cifra ni la sección, para no afirmar
  /// «ningún proyecto» sin saberlo.
  final List<Project>? projects;
  final VoidCallback? onOpenSettings;

  /// Lleva a completar el perfil; la tarjeta solo sale en el perfil propio
  /// incompleto.
  final VoidCallback? onComplete;
  final ValueChanged<Project>? onOpenProject;
  final VoidCallback? onOpenIndicators;

  /// Si hay historial se muestran los primeros proyectos y un botón para
  /// verlos todos; sin él (perfil de otra persona) se muestran todos.
  final VoidCallback? onOpenHistory;

  /// Los indicadores se están calculando y todavía no hay ninguno que mostrar.
  final bool trustLoading;

  /// Por qué no se pudieron calcular. Si no es null, la sección no muestra
  /// números sino este mensaje con [onRetryTrust].
  final String? trustError;
  final VoidCallback? onRetryTrust;

  static const _previewCount = 2;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final muted = tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          name: name,
          profile: profile,
          projectCount: projects?.length,
          isOwn: isOwn,
          onOpenSettings: onOpenSettings,
        ),
        if (isOwn && !profile.isComplete && onComplete != null) ...[
          const SizedBox(height: 12),
          _CompleteProfileCard(onPressed: onComplete!),
        ],
        const SizedBox(height: 28),
        _Section(
          title: isOwn ? 'Sobre ti' : 'Sobre mí',
          child: profile.bio.isEmpty
              ? Text(
                  isOwn
                      ? 'Aún no has escrito nada sobre ti.'
                      : 'Aún no escribió nada.',
                  style: muted,
                )
              : Container(
                  padding: const EdgeInsets.only(left: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: cs.primary, width: 3),
                    ),
                  ),
                  child: Text(profile.bio, style: tt.bodyLarge),
                ),
        ),
        const SizedBox(height: 28),
        _Section(
          title: 'Habilidades',
          child: profile.skills.isEmpty
              ? Text(
                  isOwn
                      ? 'Aún no agregas habilidades.'
                      : 'Aún no agrega habilidades.',
                  style: muted,
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in profile.skills)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          border: Border.all(color: cs.outline),
                        ),
                        child: Text(
                          skill,
                          style: tt.labelLarge?.copyWith(
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (projects case final list?) ...[
          const SizedBox(height: 28),
          _Section(
            title: 'Proyectos',
            child: list.isEmpty
                ? Text(
                    isOwn
                        ? 'Todavía no participas en ningún proyecto.'
                        : 'Todavía no participa en ningún proyecto.',
                    style: muted,
                  )
                : Column(
                    children: [
                      for (final p in list.take(
                        onOpenHistory == null ? list.length : _previewCount,
                      ))
                        ProjectTile(
                          project: p,
                          onTap: onOpenProject == null
                              ? null
                              : () => onOpenProject!(p),
                        ),
                    ],
                  ),
          ),
          if (onOpenHistory != null) ...[
            const SizedBox(height: 4),
            _WideButton(
              icon: Icons.history,
              label: list.length > _previewCount
                  ? 'Historial de colaboración (${list.length})'
                  : 'Historial de colaboración',
              onPressed: onOpenHistory!,
            ),
          ],
        ],
        const SizedBox(height: 28),
        _Section(
          title: 'Indicadores de confianza',
          child: trustError != null
              ? _TrustError(message: trustError!, onRetry: onRetryTrust)
              : trustLoading
              ? const _TrustLoading()
              : profile.hasTrustHistory
              ? InkWell(
                  onTap: onOpenIndicators,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border.all(color: cs.outline),
                    ),
                    child: TrustIndicators(
                      commitmentScore: profile.commitmentScore,
                      onTimeScore: profile.onTimeScore,
                      fulfillmentScore: profile.fulfillmentScore,
                      completedProjectsScore: profile.completedProjectsScore,
                      showTitle: false,
                    ),
                  ),
                )
              : InkWell(
                  onTap: onOpenIndicators,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          size: 32,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Aparecerán cuando ${isOwn ? 'colabores' : 'colabore'} en proyectos.',
                            style: muted,
                          ),
                        ),
                        if (onOpenIndicators != null)
                          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Banda con el avatar centrado sobre su borde, nombre, carrera y una franja de
/// cifras al estilo de las tarjetas de Descubrir (celdas separadas por líneas).
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.profile,
    this.projectCount,
    required this.isOwn,
    this.onOpenSettings,
  });

  final String name;
  final UserProfile profile;
  final int? projectCount;
  final bool isOwn;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    const avatarRadius = 46.0;

    Widget stat(String value, String label) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
    final divider = Container(width: 1, height: 44, color: cs.outline);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: cs.outline)),
      child: Column(
        children: [
          // Banda superior; el avatar la cruza.
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 84,
                width: double.infinity,
                color: cs.tertiaryContainer,
                alignment: Alignment.topRight,
                child: isOwn && onOpenSettings != null
                    ? IconButton(
                        tooltip: 'Ajustes',
                        icon: Icon(
                          Icons.settings_outlined,
                          color: cs.onTertiaryContainer,
                        ),
                        onPressed: onOpenSettings,
                      )
                    : null,
              ),
              Positioned(
                top: 84 - avatarRadius,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surface,
                    border: Border.all(color: cs.outline, width: 1.5),
                  ),
                  child: ProfileAvatar(name: name, radius: avatarRadius),
                ),
              ),
            ],
          ),
          const SizedBox(height: avatarRadius + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.academicInfo.isNotEmpty
                      ? profile.academicInfo
                      : (isOwn ? 'Agrega tu carrera' : 'Sin carrera indicada'),
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              border: Border(top: BorderSide(color: cs.outline)),
            ),
            child: Row(
              children: [
                if (projectCount != null) ...[
                  stat(
                    '$projectCount',
                    projectCount == 1 ? 'Proyecto' : 'Proyectos',
                  ),
                  divider,
                ],
                stat(
                  '${profile.skills.length}',
                  profile.skills.length == 1 ? 'Habilidad' : 'Habilidades',
                ),
                divider,
                stat(
                  profile.hasTrustHistory && profile.commitmentScore != null
                      ? '${profile.commitmentScore}%'
                      : '—',
                  'Confianza',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección en la tipografía de títulos de la app, con filete.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Divider(height: 1, color: cs.outline),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

/// Botón ancho con el aspecto de «Leer más» de las tarjetas de Descubrir.
class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: cs.tertiaryContainer,
        foregroundColor: cs.onTertiaryContainer,
        side: BorderSide(color: cs.onTertiaryContainer),
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}

/// Invita a completar carrera y habilidades; se oculta cuando ya están.
class _CompleteProfileCard extends StatelessWidget {
  const _CompleteProfileCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.tertiaryContainer,
      shape: Border.all(color: cs.onTertiaryContainer),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: cs.onTertiaryContainer),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completa tu perfil',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Agrega tu carrera y tus habilidades para que te conozcan.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mientras se calculan los indicadores.
class _TrustLoading extends StatelessWidget {
  const _TrustLoading();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const Key('profile.trust.loading'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: cs.outline)),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Cuando no se pudieron calcular: el mensaje y cómo reintentar, nunca ceros.
class _TrustError extends StatelessWidget {
  const _TrustError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      key: const Key('profile.trust.error'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: cs.outline)),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: cs.error),
          const SizedBox(width: 14),
          Expanded(child: Text(message, style: tt.bodyMedium)),
          if (onRetry != null)
            TextButton(
              key: const Key('profile.trust.retry'),
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
