import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/pages/project_detail_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/widgets/confirm_application_dialog.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';

/// Vista para "Otros proyectos" (externos / colaboraciones).
/// Un único Obx envuelve el build completo y pasa
/// listas ordinarias (no reactivas) a los children del PageView.
class OtherProjectsPage extends StatefulWidget {
  const OtherProjectsPage({super.key});

  @override
  State<OtherProjectsPage> createState() => _OtherProjectsPageState();
}

class _OtherProjectsPageState extends State<OtherProjectsPage> {
  late final PageController _pageController;
  final UserProjectsController _controller = Get.find<UserProjectsController>();
  bool _isAnimatingPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _controller.otherProjectsCategoryIndex.value,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCategorySelected(int index) {
    if (index == _controller.otherProjectsCategoryIndex.value &&
        _pageController.hasClients &&
        _pageController.page?.round() == index) {
      return;
    }
    _controller.otherProjectsCategoryIndex.value = index;
    if (_pageController.hasClients) {
      _isAnimatingPage = true;
      _pageController
          .animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          )
          .then((_) {
            if (mounted) _isAnimatingPage = false;
          });
    }
  }

  /// Chevron lateral de la cabecera: con [icon] en `null` devuelve un
  /// placeholder del mismo ancho, para que el título quede siempre centrado
  /// en la primera y en la última sección.
  Widget _headerChevron(
    BuildContext context, {
    required IconData? icon,
    String? tooltip,
    VoidCallback? onTap,
  }) {
    if (icon == null) return const SizedBox(width: 44);
    final button = IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
      padding: EdgeInsets.zero,
    );
    return SizedBox(
      width: 44,
      child: (tooltip == null || tooltip.isEmpty)
          ? button
          : Tooltip(message: tooltip, child: button),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UN SOLO Obx en el nivel superior que convierte los Rx en listas ordinarias.
    // Los children del PageView NO contienen ningún Obx adicional.
    return Obx(() {
      final currentIndex = _controller.otherProjectsCategoryIndex.value;

      // Snapshots no reactivos — plain List<Project>, seguros dentro del PageView
      final List<Project> saved = List<Project>.from(
        _controller.unappliedSavedProjects,
      );
      final List<Project> pending = List<Project>.from(
        _controller.pendingProjects,
      );
      final List<Project> active = List<Project>.from(
        _controller.activeCollaborationProjects,
      );

      final labels = ['Guardados', 'Pendientes', 'Activos'];
      final counts = [saved.length, pending.length, active.length];

      return Column(
        children: [
          // Cabecera: el nombre de la sección gigante + chevrons a los lados.
          // Todo vive dentro del Obx superior — FUERA del PageView — así es seguro.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    _headerChevron(
                      context,
                      icon: currentIndex > 0 ? Icons.chevron_left : null,
                      tooltip: currentIndex > 0
                          ? 'Sección anterior: ${labels[currentIndex - 1]}'
                          : null,
                      onTap: currentIndex > 0
                          ? () => _onCategorySelected(currentIndex - 1)
                          : null,
                    ),
                    Expanded(
                      // El título cambia con la página: es la sección que se
                      // está mirando, no un menú que haya que abrir.
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Column(
                          key: ValueKey<int>(currentIndex),
                          children: [
                            Text(
                              labels[currentIndex],
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              counts[currentIndex] == 1
                                  ? '1 proyecto'
                                  : '${counts[currentIndex]} proyectos',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _headerChevron(
                      context,
                      icon: currentIndex < labels.length - 1
                          ? Icons.chevron_right
                          : null,
                      tooltip: currentIndex < labels.length - 1
                          ? 'Sección siguiente: ${labels[currentIndex + 1]}'
                          : null,
                      onTap: currentIndex < labels.length - 1
                          ? () => _onCategorySelected(currentIndex + 1)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Dots: feedback visual del swipe + toque directo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(labels.length, (dotIndex) {
                      final isActive = dotIndex == currentIndex;
                      return GestureDetector(
                        onTap: () => _onCategorySelected(dotIndex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: isActive ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline
                                      .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (!_isAnimatingPage) {
                  _controller.otherProjectsCategoryIndex.value = index;
                }
              },
              // Los children NO tienen Obx — reciben datos planos y son widgets puros.
              children: [
                _ProjectsCategoryList(
                  key: const ValueKey('saved'),
                  projects: saved,
                  emptyText:
                      'No tienes proyectos guardados sin postular.\n'
                      'Explora y guarda proyectos desde la pestaña Descubrir.',
                  emptyIcon: Icons.bookmark_border,
                  buildTrailing: (project) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Desguardar sin salir de la lista.
                      IconButton(
                        onPressed: () async {
                          await _controller.toggleSaveProject(project);
                        },
                        tooltip: 'Quitar de guardados',
                        icon: const Icon(
                          Icons.bookmark_remove_outlined,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: () => showConfirmApplicationDialog(
                          context: context,
                          project: project,
                        ),
                        style: FilledButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ),
                _ProjectsCategoryList(
                  key: const ValueKey('pending'),
                  projects: pending,
                  emptyText:
                      'No tienes postulaciones pendientes de validación.\n'
                      'Postula a proyectos para ver el estado de tu solicitud.',
                  emptyIcon: Icons.hourglass_empty,
                  buildTrailing: (project) => _StatusBadge(
                    label: 'Pendiente',
                    icon: Icons.hourglass_top,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    textColor: Theme.of(context)
                        .colorScheme
                        .onTertiaryContainer,
                    borderColor: Theme.of(context).colorScheme.outline,
                  ),
                ),
                _ProjectsCategoryList(
                  key: const ValueKey('active'),
                  projects: active,
                  emptyText:
                      'Aún no tienes colaboraciones activas.\n'
                      'Cuando un líder acepte tu solicitud, el proyecto aparecerá aquí.',
                  emptyIcon: Icons.volunteer_activism_outlined,
                  buildTrailing: (project) => _StatusBadge(
                    label: 'Colaborando',
                    icon: Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    textColor: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer,
                    borderColor: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets puros (sin reactividad GetX interna)
// ---------------------------------------------------------------------------

class _ProjectsCategoryList extends StatelessWidget {
  final List<Project> projects;
  final String emptyText;
  final IconData emptyIcon;
  final Widget Function(Project project) buildTrailing;

  const _ProjectsCategoryList({
    super.key,
    required this.projects,
    required this.emptyText,
    required this.emptyIcon,
    required this.buildTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 56,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                emptyText,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectTile(
          project: project,
          onTap: () => Get.to(() => ProjectDetailPage(project: project)),
          trailing: buildTrailing(project),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
