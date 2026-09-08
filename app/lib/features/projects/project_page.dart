import 'package:flutter/material.dart';

class ProjectPage extends StatelessWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.primaryContainer,
      child: Center(
        child: Text(
          'proyectos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
