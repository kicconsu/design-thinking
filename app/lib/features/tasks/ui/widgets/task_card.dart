import 'package:flutter/material.dart';

import '../../domain/models/project_task.dart';
import '../../domain/models/task_status.dart';

/// Tarjeta de una tarea en el gabinete. Las pendientes traen el botón
/// «Reservar tarea»; las demás, quién las tiene.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.assignee,
    this.busy = false,
    this.onTap,
    this.onReserve,
  });

  final ProjectTask task;

  /// Texto de "Reservada por ...", ya resuelto por el controlador.
  final String? assignee;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback? onReserve;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                task.title,
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: task.checklistProgress,
                  minHeight: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                ),
              ],
              if (assignee != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Reservada por $assignee',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              if (task.status == TaskStatus.todo && onReserve != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: busy ? null : onReserve,
                    child: const Text('Reservar tarea'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
