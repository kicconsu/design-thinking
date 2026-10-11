import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/projects/domain/models/project_task.dart';
import 'package:imker/features/projects/ui/viewmodels/project_management_controller.dart';
import 'checklist_editor.dart';
import 'management_panel_frame.dart';
import 'task_comments_view.dart';

/// Panel "Progreso de tarea": descripción + checklist, y comentarios.
///
/// Recuerda la última tarea abierta para poder seguir dibujándola mientras el
/// panel se desliza hacia afuera, cuando [ProjectManagementController.selectedTaskId]
/// ya volvió a null.
class TaskProgressPanel extends StatefulWidget {
  const TaskProgressPanel({super.key});

  @override
  State<TaskProgressPanel> createState() => _TaskProgressPanelState();
}

class _TaskProgressPanelState extends State<TaskProgressPanel> {
  String? _lastTaskId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectManagementController>();

    return Obx(() {
      final current = controller.selectedTaskId.value;
      if (current != null) _lastTaskId = current;
      final task = controller.taskById(_lastTaskId);
      if (task == null) return const SizedBox.shrink();
      // La clave reinicia el borrador al abrir otra tarea.
      return _TaskProgressContent(key: ValueKey(task.id), taskId: task.id);
    });
  }
}

class _TaskProgressContent extends StatefulWidget {
  const _TaskProgressContent({super.key, required this.taskId});

  final String taskId;

  @override
  State<_TaskProgressContent> createState() => _TaskProgressContentState();
}

class _TaskProgressContentState extends State<_TaskProgressContent> {
  final _description = TextEditingController();
  late List<ChecklistEntry> _items;
  int _tab = 0; // 0: Descripción, 1: Comentarios

  @override
  void initState() {
    super.initState();
    final task = Get.find<ProjectManagementController>().taskById(widget.taskId)!;
    _description.text = task.description;
    _items = [for (final s in task.subtasks) ChecklistEntry(s.title, checked: s.done)];
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final controller = Get.find<ProjectManagementController>();
    controller.saveTask(
      widget.taskId,
      description: _description.text.trim(),
      subtasks: [for (final e in _items) Subtask(title: e.label, done: e.checked)],
    );
    final done = controller.taskById(widget.taskId)?.status == TaskStatus.done;
    Get.snackbar(
      'Tarea guardada',
      done ? 'Completaste todas las subtareas: la tarea pasó a "Terminadas".' : 'Tus cambios se guardaron.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectManagementController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final task = controller.taskById(widget.taskId)!;

    return ManagementPanelFrame(
      title: 'Progreso de tarea',
      onBack: controller.showCabinet,
      tabs: SegmentedTabSwitch(
        tabs: const ['Descripción', 'Comentarios'],
        selectedIndex: _tab,
        onTabSelected: (i) => setState(() => _tab = i),
      ),
      body: _tab == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(task.title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Divider(color: cs.outline),
                const SizedBox(height: 8),
                Text('Descripción', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: cs.outline),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Checklist de progreso',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ChecklistEditor(
                  initial: _items,
                  hint: 'Escribe una subtarea',
                  addedChecked: false,
                  onChanged: (v) => _items = List.of(v),
                ),
              ],
            )
          : TaskCommentsView(taskId: widget.taskId),
      bottom: _tab == 0 ? PanelButton(label: 'Guardar', onPressed: _save) : null,
    );
  }
}
