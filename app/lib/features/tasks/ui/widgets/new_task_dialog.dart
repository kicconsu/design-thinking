import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/utils/clock.dart';

import '../../domain/models/task_deadline.dart';

/// Diálogo para crear una tarea. Se cierra con
/// `({title, description, deadlineDay})` o con `null` si se cancela.
///
/// [deadlineDay] es el día límite elegido (opcional, nunca anterior a hoy);
/// la tarea vence al final de ese día (ver `TaskDeadline`).
class NewTaskDialog extends StatefulWidget {
  const NewTaskDialog({super.key, this.clock = systemClock});

  /// De dónde sale "hoy", para no permitir fechas pasadas.
  final Clock clock;

  @override
  State<NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<NewTaskDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _showError = false;
  DateTime? _deadlineDay;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = widget.clock();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDeadline() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDay ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      helpText: 'Fecha límite',
    );
    if (picked != null) setState(() => _deadlineDay = picked);
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Get.back(
      result: (
        title: title,
        description: _description.text.trim(),
        deadlineDay: _deadlineDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = _deadlineDay;
    return AlertDialog(
      title: const Text('Crear tarea'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('task.new.title'),
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre de la tarea',
              errorText: _showError ? 'Escribe un nombre' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('task.new.description'),
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('task.new.deadline'),
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    day == null
                        ? 'Fecha límite (opcional)'
                        : 'Límite: ${TaskDeadline.formatDay(day)}',
                  ),
                ),
              ),
              if (day != null)
                IconButton(
                  key: const Key('task.new.deadline.clear'),
                  tooltip: 'Quitar fecha límite',
                  onPressed: () => setState(() => _deadlineDay = null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Crear')),
      ],
    );
  }
}
