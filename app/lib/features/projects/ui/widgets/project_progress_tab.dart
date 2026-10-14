import 'package:flutter/material.dart';

/// Pestaña "Progreso" de la información del proyecto: el porcentaje de tareas
/// terminadas ([progress], de 0 a 100).
class ProjectProgressTab extends StatelessWidget {
  const ProjectProgressTab({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final value = progress.clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso general',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Porcentaje de Finalización',
                      style: tt.bodyMedium,
                    ),
                  ),
                  Text(
                    '${value.round()}%',
                    key: const ValueKey('progress-percent'),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                ),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 14,
                  backgroundColor: cs.surface,
                  color: cs.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
