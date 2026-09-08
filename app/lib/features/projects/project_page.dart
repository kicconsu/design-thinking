import 'package:f_clean_template/core/shared_widgets/offset_app_bar.dart';
import 'package:f_clean_template/features/projects/ui/views/project_card.dart';
import 'package:flutter/material.dart';

class ProjectPage extends StatelessWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OffsetAppBar(),
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: ProjectCard(),
      ),
    );
  }
}
