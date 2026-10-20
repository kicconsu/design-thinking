import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/utils/clock.dart';
import 'package:imker/core/widgets/checklist_editor.dart';
import 'package:imker/core/widgets/imker_app_bar.dart';
import 'package:imker/core/widgets/imker_bottom_nav_bar.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/projects/domain/models/project.dart';

import '../../domain/models/project_task.dart';
import '../../domain/models/subtask.dart';
import '../../domain/models/task_deadline.dart';
import '../../domain/models/task_status.dart';
import '../viewmodels/task_progress_controller.dart';
import '../widgets/task_comments_view.dart';

/// Progreso de una tarea: descripción y checklist (editables por quien la
/// reservó) y comentarios.
class TaskProgressPage extends StatefulWidget {
  const TaskProgressPage({
    super.key,
    required this.project,
    required this.task,
    this.currentUserId,
    this.clock = systemClock,
  });

  final Project project;
  final ProjectTask task;

  /// Sustituye a la sesión real: solo para pruebas.
  final String Function()? currentUserId;

  /// De dónde sale «ahora» (vencida o no): solo se cambia en pruebas.
  final Clock clock;

  @override
  State<TaskProgressPage> createState() => _TaskProgressPageState();
}

class _TaskProgressPageState extends State<TaskProgressPage> {
  late final TaskProgressController _controller;
  late final String _tag;
  final _description = TextEditingController();
  int _tab = 0; // 0: Descripción, 1: Comentarios

  @override
  void initState() {
    super.initState();
    // Un controlador por entrada: abrir otra tarea no hereda la anterior.
    _tag = '${widget.task.id}#${identityHashCode(this)}';
    _controller = Get.put(
      TaskProgressController(
        widget.task,
        currentUserId: widget.currentUserId,
        projectOwnerId: widget.project.owner,
        clock: widget.clock,
      ),
      tag: _tag,
    );
    _description.text = widget.task.description;
  }

  @override
  void dispose() {
    _description.dispose();
    Get.delete<TaskProgressController>(tag: _tag, force: true);
    super.dispose();
  }

  void _toast(String title, String message) =>
      Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);

  void _selectTab(int index) {
    setState(() => _tab = index);
    // Los comentarios se leen la primera vez que se abre la pestaña.
    if (index == 1 && !_controller.commentsLoaded.value) {
      _controller.loadComments();
    }
  }

  Future<void> _pickDeadline() async {
    final today = _controller.today;
    final current = _controller.task.value.deadline?.toLocal();
    final initial = current == null || current.isBefore(today)
        ? today
        : current;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      helpText: 'Fecha límite',
    );
    if (picked == null) return;
    await _changeDeadline(picked);
  }

  Future<void> _changeDeadline(DateTime? day) async {
    final error = await _controller.setDeadline(day);
    if (error != null) _toast('No se pudo cambiar la fecha', error);
  }

  Future<void> _save() async {
    final error = await _controller.save(_description.text);
    if (error != null) {
      _toast('No se pudo guardar', error);
      return;
    }
    final done = _controller.task.value.status == TaskStatus.done;
    _toast(
      'Tarea guardada',
      done
          ? 'Completaste todas las subtareas: la tarea pasó a "Terminadas".'
          : 'Tus cambios se guardaron.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: const ImkerAppBar(),
      // Estas páginas cuelgan de la pestaña Proyectos (índice 1).
      bottomNavigationBar: ImkerBottomNavBar(
        currentIndex: 1,
        onTap: (index) => Get.find<HomeViewModel>().openTab(index),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(color: cs.outline),
                ),
                child: Text(
                  widget.project.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Progreso de tarea',
                        textAlign: TextAlign.center,
                        style: tt.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      SegmentedTabSwitch(
                        tabs: const ['Descripción', 'Comentarios'],
                        selectedIndex: _tab,
                        onTabSelected: _selectTab,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _tab == 0 ? _details(cs, tt) : _comments(),
                        ),
                      ),
                      if (_tab == 0 && _controller.canEdit) ...[
                        const SizedBox(height: 8),
                        Obx(
                          () => FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            onPressed: _controller.isSaving.value
                                ? null
                                : _save,
                            child: _controller.isSaving.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Guardar'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _details(ColorScheme cs, TextTheme tt) {
    final editable = _controller.canEdit;
    final reason = _controller.readOnlyReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.task.title,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Divider(color: cs.outline),
        _deadline(cs, tt),
        if (reason != null) ...[
          Text(
            reason,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Descripción',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _description,
          readOnly: !editable,
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
          initial: [
            for (final s in _controller.checklist)
              ChecklistEntry(s.title, checked: s.done),
          ],
          hint: 'Escribe una subtarea',
          addedChecked: false,
          enabled: editable,
          onChanged: (entries) => _controller.setChecklist([
            for (final e in entries) Subtask(title: e.label, done: e.checked),
          ]),
        ),
      ],
    );
  }

  /// Fecha límite de la tarea, con la señal de vencida y, para quien puede
  /// moverla, los botones de cambiar y quitar.
  Widget _deadline(ColorScheme cs, TextTheme tt) {
    return Obx(() {
      final task = _controller.task.value;
      final deadline = task.deadline;
      final overdue = _controller.isOverdue;
      final canEdit = _controller.canEditDeadline;
      if (deadline == null && !canEdit) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              overdue ? Icons.warning_amber_rounded : Icons.event_outlined,
              size: 20,
              color: overdue ? cs.error : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                key: const Key('task.deadline'),
                deadline == null
                    ? 'Sin fecha límite'
                    : overdue
                    ? 'Vencida el ${TaskDeadline.formatDay(deadline)}'
                    : 'Vence el ${TaskDeadline.formatDay(deadline)}',
                style: tt.bodyMedium?.copyWith(
                  color: overdue ? cs.error : null,
                  fontWeight: overdue ? FontWeight.bold : null,
                ),
              ),
            ),
            if (canEdit) ...[
              IconButton(
                key: const Key('task.deadline.edit'),
                tooltip: deadline == null
                    ? 'Poner fecha límite'
                    : 'Cambiar fecha límite',
                onPressed: _controller.isSavingDeadline.value
                    ? null
                    : _pickDeadline,
                icon: const Icon(Icons.edit_calendar_outlined),
              ),
              if (deadline != null)
                IconButton(
                  key: const Key('task.deadline.clear'),
                  tooltip: 'Quitar fecha límite',
                  onPressed: _controller.isSavingDeadline.value
                      ? null
                      : () => _changeDeadline(null),
                  icon: const Icon(Icons.event_busy_outlined),
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _comments() {
    return Obx(
      () => TaskCommentsView(
        comments: _controller.comments.toList(),
        isLoading: _controller.isLoadingComments.value,
        loaded: _controller.commentsLoaded.value,
        isSending: _controller.isSending.value,
        error: _controller.commentsError.value,
        authorOf: _controller.authorOf,
        onSend: _controller.addComment,
        onRetry: _controller.loadComments,
      ),
    );
  }
}
