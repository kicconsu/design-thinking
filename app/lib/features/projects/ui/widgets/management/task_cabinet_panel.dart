import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/projects/domain/models/project_task.dart';
import 'package:imker/features/projects/ui/viewmodels/project_management_controller.dart';
import 'management_panel_frame.dart';

/// Panel "Gabinete de tareas": tareas pendientes, en progreso y terminadas.
class TaskCabinetPanel extends StatefulWidget {
  const TaskCabinetPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<TaskCabinetPanel> createState() => _TaskCabinetPanelState();
}

class _TaskCabinetPanelState extends State<TaskCabinetPanel> {
  static const _statuses = [TaskStatus.pending, TaskStatus.inProgress, TaskStatus.done];

  int _tab = 0;

  Future<void> _createTask() async {
    final result = await Get.dialog<({String title, String description})>(const _NewTaskDialog());
    if (result == null) return;
    Get.find<ProjectManagementController>().createTask(
      projectId: widget.projectId,
      title: result.title,
      description: result.description,
    );
    setState(() => _tab = 0);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectManagementController>();

    return ManagementPanelFrame(
      title: 'Gabinete de tareas',
      onBack: controller.showInfo,
      tabs: SegmentedTabSwitch(
        tabs: const ['Pendientes', 'En Progreso', 'Terminadas'],
        selectedIndex: _tab,
        onTabSelected: (i) => setState(() => _tab = i),
      ),
      body: Obx(() {
        final status = _statuses[_tab];
        final tasks = controller.tasksOf(widget.projectId, status);
        if (tasks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              switch (status) {
                TaskStatus.pending => 'No hay tareas pendientes.',
                TaskStatus.inProgress => 'No hay tareas en progreso.',
                TaskStatus.done => 'Todavía no hay tareas terminadas.',
              },
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Column(
          children: [
            for (final task in tasks)
              _TaskCard(
                task: task,
                onTap: () => controller.openTask(task.id),
                onReserve: () {
                  controller.reserveTask(task.id);
                  Get.snackbar(
                    'Tarea reservada',
                    'La encontrarás en "En Progreso".',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
          ],
        );
      }),
      bottom: PanelButton(label: 'Crear tarea', onPressed: _createTask),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap, required this.onReserve});

  final ProjectTask task;
  final VoidCallback onTap;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outline)),
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
                  value: task.progress,
                  minHeight: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                ),
              ],
              if (task.assignee != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Reservada por ${task.assignee}',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              if (task.status == TaskStatus.pending) ...[
                const SizedBox(height: 10),
                Center(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: onReserve,
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

class _NewTaskDialog extends StatefulWidget {
  const _NewTaskDialog();

  @override
  State<_NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<_NewTaskDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Get.back(result: (title: title, description: _description.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear tarea'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre de la tarea',
              errorText: _showError ? 'Escribe un nombre' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
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
