import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imker/core/widgets/filter_drowpdown_button.dart';

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

      return Column(
        children: [
          // Cabecera: Dropdown a la izquierda + dots de swipe a la derecha.
          // Todo vive dentro del Obx superior — FUERA del PageView — así es seguro.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PopupMenuButton: siempre abre hacia abajo desde el botón,
                // sin el comportamiento de "subir" del DropdownButton estándar
                FilterDropdownButton(
                  labels: [
                    'Guardados (${saved.length})',
                    'Pendientes (${pending.length})',
                    'Activos (${active.length})',
                    ],
                    currentIndex: currentIndex,
                    onSelected: _onCategorySelected,
                ),

                // Dots: feedback visual del swipe + toque directo
                Row(
                  children: [
                    Text(
                      'Desliza',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...List.generate(3, (dotIndex) {
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
                  buildTrailing: (project) => FilledButton(
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
