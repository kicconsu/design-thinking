import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/pages/project_detail_page.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';

/// Todos los proyectos de la persona: los que creó y en los que colabora.
class ProfileProjectsPage extends StatelessWidget {
  const ProfileProjectsPage({super.key, required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Proyectos'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: projects.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Todavía no hay proyectos para mostrar.',
                    style: tt.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  for (final p in projects)
                    ProjectTile(
                      project: p,
                      onTap: () => Get.to(() => ProjectDetailPage(project: p)),
                    ),
                ],
              ),
      ),
    );
  }
}
