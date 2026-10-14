import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/pages/project_detail_page.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';

/// Historial de colaboración: proyectos actuales y, aparte, los anteriores
/// (los que ya cerraron).
class CollaborationHistoryPage extends StatelessWidget {
  const CollaborationHistoryPage({
    super.key,
    required this.created,
    required this.collaborating,
  });

  /// Proyectos que creó la persona.
  final List<Project> created;

  /// Proyectos en los que colabora hoy.
  final List<Project> collaborating;

  Widget _section(
    BuildContext context,
    String title,
    List<Project> projects,
    String empty,
  ) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (projects.isEmpty)
          Text(
            empty,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          )
        else
          for (final p in projects)
            ProjectTile(
              project: p,
              onTap: () => Get.to(() => ProjectDetailPage(project: p)),
            ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Un proyecto cerrado pasa a "anteriores" y sale de las otras dos
    // secciones, que muestran solo lo que sigue abierto.
    final currentlyCollaborating = [
      for (final p in collaborating)
        if (p.isOpen) p,
    ];
    final currentlyCreated = [
      for (final p in created)
        if (p.isOpen) p,
    ];
    final previous = [
      for (final p in [...created, ...collaborating])
        if (!p.isOpen) p,
    ];

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Historial de colaboración'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _section(
              context,
              'Colaborando ahora',
              currentlyCollaborating,
              'No colabora en ningún proyecto ahora.',
            ),
            _section(
              context,
              'Proyectos creados',
              currentlyCreated,
              'No ha creado proyectos abiertos.',
            ),
            _section(
              context,
              'Proyectos anteriores',
              previous,
              'Aquí aparecerán los proyectos que ya cerraron.',
            ),
          ],
        ),
      ),
    );
  }
}
