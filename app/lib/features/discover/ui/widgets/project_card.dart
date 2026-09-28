import 'package:imker/features/auth/ui/widgets/account_required_prompt.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/pages/project_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Jobs at top
          _JobsRow(jobs: project.jobs, tt: tt),
          // Image takes remaining vertical space with heart button overlay
          Expanded(flex: 4, child: _ProjectImage(project: project)),
          Divider(color: cs.outline, thickness: 1, height: 1),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              project.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.titleLarge?.copyWith(),
            ),
          ),
          Divider(color: cs.outline, thickness: 1, height: 1),
          // Skills and description
          Expanded(
            flex: 3,
            child: _SkillsAndDescription(
              skills: project.skills,
              description: project.description,
              tt: tt,
              dividerColor: cs.outline,
            ),
          ),
          Divider(color: cs.outline, thickness: 1, height: 1),
          // Buttons
          _ActionButtons(tt: tt, cs: cs, project: project),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _JobsRow extends StatelessWidget {
  final List<String> jobs;
  final TextTheme tt;

  const _JobsRow({required this.jobs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        jobs.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tt.labelMedium?.copyWith(letterSpacing: 0.5),
      ),
    );
  }
}

class _ProjectImage extends StatelessWidget {
  final Project project;

  const _ProjectImage({required this.project});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          project.imageUrl,
          fit: BoxFit.fill,
          errorBuilder: (_, _, _) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
        Positioned(top: 8, right: 8, child: _FavoriteButton(project: project)),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final Project project;

  const _FavoriteButton({required this.project});

  void _showNotice(BuildContext context, bool nowSaved) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (nowSaved) {
      Get.snackbar(
        '¡Proyecto guardado!',
        "Entra a la pestaña 'Proyectos' para más detalles.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: cs.tertiaryContainer,
        icon: Icon(Icons.favorite, color: Colors.red),
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            Get.find<HomeViewModel>().changePage(1);
          },
          child: Text('Ir a Proyectos', style: tt.labelSmall?.copyWith()),
        ),
      );
    } else {
      Get.snackbar(
        'Proyecto removido',
        'El proyecto se eliminó de tus proyectos guardados.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cs.surfaceContainerHigh,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showAppliedNotice(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Get.snackbar(
      'Ya postulaste a este proyecto',
      "Sigue tu postulación en la pestaña 'Proyectos' → Pendientes.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: cs.tertiaryContainer,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsController = Get.find<UserProjectsController>();

    return Obx(() {
      final isOwner = projectsController.isOwner(project);
      if (isOwner) return const SizedBox.shrink();

      // Ya hay una postulación pendiente: el estado lo manda "Pendientes",
      // así que aquí sólo se informa, no se alterna.
      if (projectsController.isApplied(project.id)) {
        return Material(
          color: Colors.black45,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(
              Icons.how_to_reg_outlined,
              color: Colors.amberAccent,
              size: 24,
            ),
            tooltip: 'Postulación pendiente',
            onPressed: () => _showAppliedNotice(context),
          ),
        );
      }

      final saved = projectsController.isSaved(project.id);

      return Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            color: saved ? Colors.redAccent : Colors.white,
            size: 24,
          ),
          tooltip: saved ? 'Quitar de guardados' : '¡Me interesa!',
          onPressed: (() async {
            final nowSaved = await projectsController.toggleSaveProject(
              project,
            );
            if (!context.mounted) return;
            _showNotice(context, nowSaved);
          }).guarded('Para guardar proyectos necesitas una cuenta real.'),
        ),
      );
    });
  }
}

class _SkillsAndDescription extends StatelessWidget {
  final List<String> skills;
  final String description;
  final TextTheme tt;
  final Color dividerColor;

  const _SkillsAndDescription({
    required this.skills,
    required this.description,
    required this.tt,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habilidades requeridas',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...skills.map(
                    (s) => Text(
                      '· $s',
                      style: tt.bodySmall?.copyWith(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(color: dividerColor, thickness: 1, width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                description,
                style: tt.bodySmall?.copyWith(),
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ColorScheme cs;
  final Project project;
  final TextTheme tt;

  const _ActionButtons({
    required this.tt,
    required this.cs,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    final projectsController = Get.find<UserProjectsController>();
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: cs.inversePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Colors.black, width: 1),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Get.to(() => ProjectDetailPage(project: project));
              },
              style: buttonStyle,
              icon: const Icon(Icons.menu_book),
              label: Text('Leer más', style: tt.headlineSmall),
            ),
          ),
          Obx(() {
            final isOwner = projectsController.isOwner(project);
            if (!isOwner) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Tu proyecto',
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
