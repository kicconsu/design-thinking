import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/imker_app_bar.dart';
import 'package:imker/core/widgets/imker_bottom_nav_bar.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/projects/domain/models/project.dart';

import '../../domain/models/project_task.dart';
import '../../domain/models/task_status.dart';
import '../viewmodels/task_board_controller.dart';
import 'task_progress_page.dart';
import '../widgets/new_task_dialog.dart';
import '../widgets/task_card.dart';

import 'package:imker/core/utils/app_keys.dart';

/// Gabinete de tareas de un proyecto: pendientes, en progreso y terminadas.
class TaskBoardPage extends StatefulWidget {
  const TaskBoardPage({super.key, required this.project, this.currentUserId});

  final Project project;

  /// Sustituye a la sesión real: solo para pruebas.
  final String Function()? currentUserId;

  @override
  State<TaskBoardPage> createState() => _TaskBoardPageState();
}

class _TaskBoardPageState extends State<TaskBoardPage> {
  static const _statuses = [TaskStatus.todo, TaskStatus.doing, TaskStatus.done];
  static const _emptyTexts = [
    'No hay tareas pendientes.',
    'No hay tareas en progreso.',
    'Todavía no hay tareas terminadas.',
  ];

  late final TaskBoardController _controller;
  late final String _tag;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Un controlador por entrada: abrir otro proyecto no hereda el anterior.
    _tag = '${widget.project.id}#${identityHashCode(this)}';
    _controller = Get.put(
      TaskBoardController(widget.project, currentUserId: widget.currentUserId),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<TaskBoardController>(tag: _tag, force: true);
    super.dispose();
  }

  void _toast(String title, String message) =>
      Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);

  Future<void> _createTask() async {
    final result =
        await Get.dialog<
          ({String title, String description, DateTime? deadlineDay})
        >(const NewTaskDialog());
    if (result == null) return;
    final error = await _controller.createTask(
      title: result.title,
      description: result.description,
      deadlineDay: result.deadlineDay,
    );
    if (error != null) {
      _toast('No se pudo crear la tarea', error);
      return;
    }
    if (mounted) setState(() => _tab = 0);
  }

  /// Abre el progreso de la tarea y, al volver, relee el tablero: ahí pudo
  /// cambiar su estado.
  Future<void> _openTask(ProjectTask task) async {
    await Get.to(
      () => TaskProgressPage(
        project: widget.project,
        task: task,
        currentUserId: widget.currentUserId,
      ),
    );
    if (mounted) _controller.load();
  }

  Future<void> _reserve(ProjectTask task) async {
    final error = await _controller.reserveTask(task);
    if (error != null) {
      _toast('No se pudo reservar', error);
      return;
    }
    _toast('Tarea reservada', 'La encontrarás en "En Progreso".');
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
                        'Gabinete de tareas',
                        textAlign: TextAlign.center,
                        style: tt.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      SegmentedTabSwitch(
                        keyPrefix: AppKeys.taskBoardTabs,
                        tabs: const ['Pendientes', 'En Progreso', 'Terminadas'],
                        selectedIndex: _tab,
                        onTabSelected: (i) => setState(() => _tab = i),
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _list()),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: AppKeys.createTask,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: _createTask,
                        child: const Text('Crear tarea'),
                      ),
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

  Widget _list() {
    return Obx(() {
      if (_controller.isLoading.value && _controller.tasks.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final tasks = _controller.tasksOf(_statuses[_tab]);
      return RefreshIndicator(
        onRefresh: _controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  _emptyTexts[_tab],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (final task in tasks)
              TaskCard(
                key: ValueKey(task.id),
                task: task,
                assignee: _controller.assigneeLabel(task),
                busy: _controller.reserving.contains(task.id),
                onReserve: () => _reserve(task),
                onTap: () => _openTask(task),
              ),
          ],
        ),
      );
    });
  }
}
