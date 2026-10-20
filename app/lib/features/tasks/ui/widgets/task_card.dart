import 'package:flutter/material.dart';

import 'package:imker/core/utils/clock.dart';

import '../../domain/models/project_task.dart';
import '../../domain/models/task_deadline.dart';
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
    this.clock = systemClock,
  });

  final ProjectTask task;

  /// Texto de "Reservada por ...", ya resuelto por el controlador.
  final String? assignee;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback? onReserve;

  /// De dónde sale «ahora», para marcar las tareas vencidas.
  final Clock clock;

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
              if (task.deadline case final deadline?) ...[
                const SizedBox(height: 6),
                _DeadlineLabel(
                  key: Key('task.card.deadline.${task.id}'),
                  deadline: deadline,
                  overdue: task.isOverdueAt(clock()),
                  done: task.isDone,
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

/// «Vence el 20/03/2026», o «Vencida el …» en rojo si ya pasó sin terminarse.
class _DeadlineLabel extends StatelessWidget {
  const _DeadlineLabel({
    super.key,
    required this.deadline,
    required this.overdue,
    required this.done,
  });

  final DateTime deadline;
  final bool overdue;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = overdue ? cs.error : cs.onSurfaceVariant;
    final day = TaskDeadline.formatDay(deadline);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          overdue ? Icons.warning_amber_rounded : Icons.event_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          overdue
              ? 'Vencida el $day'
              : done
              ? 'Límite: $day'
              : 'Vence el $day',
          style: tt.bodySmall?.copyWith(
            color: color,
            fontWeight: overdue ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
