import 'package:f_clean_template/core/navigation/ui/viewmodels/navigation_controller.dart';
import 'package:f_clean_template/features/discover/domain/models/project.dart';
import 'package:f_clean_template/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:f_clean_template/features/projects/ui/views/project_detail_page.dart';
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
        color: cs.onPrimaryContainer,
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Jobs at top
          _JobsRow(jobs: project.jobs, textColor: cs.onPrimary, tt: tt),
          Divider(color: cs.outline, thickness: 1, height: 1),
          // Image takes remaining vertical space
          Expanded(
            flex: 4,
            child: _ProjectImage(imageUrl: project.imageUrl),
          ),
          Divider(color: cs.outline, thickness: 1, height: 1),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              project.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.titleLarge?.copyWith(color: cs.onPrimary),
            ),
          ),
          Divider(color: cs.outline, thickness: 1, height: 1),
          // Skills and description
          Expanded(
            flex: 3,
            child: _SkillsAndDescription(
              skills: project.skills,
              description: project.description,
              textColor: cs.onPrimary,
              tt: tt,
              dividerColor: cs.outline,
            ),
          ),
          Divider(color: cs.outline, thickness: 1, height: 1),
          // Buttons
          _ActionButtons(textColor: cs.onPrimary, cs: cs, project: project),
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
  final Color textColor;
  final TextTheme tt;

  const _JobsRow({
    required this.jobs,
    required this.textColor,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        jobs.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tt.labelMedium?.copyWith(color: textColor, letterSpacing: 0.5),
      ),
    );
  }
}



class _ProjectImage extends StatelessWidget {
  final String imageUrl;

  const _ProjectImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined, size: 48),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _SkillsAndDescription extends StatelessWidget {
  final List<String> skills;
  final String description;
  final Color textColor;
  final TextTheme tt;
  final Color dividerColor;

  const _SkillsAndDescription({
    required this.skills,
    required this.description,
    required this.textColor,
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
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...skills.map(
                    (s) => Text(
                      '· $s',
                      style: tt.bodySmall?.copyWith(color: textColor),
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
                style: tt.bodySmall?.copyWith(color: textColor),
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
  final Color textColor;
  final ColorScheme cs;
  final Project project;

  const _ActionButtons({
    required this.textColor,
    required this.cs,
    required this.project,
  });

  void _showSavedNotice(BuildContext context) {
    Get.snackbar(
      '¡Proyecto guardado!',
      "Entra a la pestaña 'Proyectos' para más detalles.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: cs.tertiaryContainer,
      colorText: cs.onTertiaryContainer,
      icon: Icon(Icons.bookmark, color: cs.onTertiaryContainer),
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          Get.find<NavigationController>().changePage(1);
        },
        child: Text(
          'Ir a Proyectos',
          style: TextStyle(
            color: cs.onTertiaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsController = Get.find<UserProjectsController>();
    final buttonStyle = FilledButton.styleFrom(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Colors.black, width: 1),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: () {
              Get.to(() => ProjectDetailPage(project: project));
            },
            style: buttonStyle,
            icon: const Icon(Icons.menu_book),
            label: Text('Leer más', style: TextStyle(color: textColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final saved = projectsController.isSaved(project.id);
              return FilledButton.icon(
                onPressed: saved
                    ? null
                    : () {
                        projectsController.saveProject(project);
                        _showSavedNotice(context);
                      },
                style: buttonStyle,
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                label: Text(
                  saved ? 'Guardado' : '¡Me interesa!',
                  style: TextStyle(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}