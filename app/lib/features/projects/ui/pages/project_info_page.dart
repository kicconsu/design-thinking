import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/imker_app_bar.dart';
import 'package:imker/core/widgets/imker_bottom_nav_bar.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/pages/member_profile_page.dart';
import 'package:imker/features/projects/ui/viewmodels/project_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/project_members_controller.dart';
import 'package:imker/features/projects/ui/widgets/project_members_tab.dart';
import 'package:imker/features/projects/ui/widgets/project_progress_tab.dart';
import 'package:imker/features/tasks/ui/pages/task_board_page.dart';

/// Información de un proyecto del que el usuario es parte (lo creó o colabora
/// en él): pestañas Progreso, Info. básica y Miembros.
class ProjectInfoPage extends StatefulWidget {
  const ProjectInfoPage({super.key, required this.project, this.currentUserId});

  final Project project;

  /// Sustituye a la sesión real: solo para pruebas.
  final String Function()? currentUserId;

  @override
  State<ProjectInfoPage> createState() => _ProjectInfoPageState();
}

class _ProjectInfoPageState extends State<ProjectInfoPage> {
  static const _tabs = ['Progreso', 'Info. básica', 'Miembros'];

  late final ProjectInfoController _controller;
  late final ProjectMembersController _members;
  late final String _tag;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Un controlador por entrada: abrir otro proyecto no hereda el anterior.
    _tag = '${widget.project.id}#${identityHashCode(this)}';
    _controller = Get.put(ProjectInfoController(widget.project), tag: _tag);
    _members = Get.put(
      ProjectMembersController(
        widget.project.id,
        currentUserId: widget.currentUserId,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<ProjectInfoController>(tag: _tag, force: true);
    Get.delete<ProjectMembersController>(tag: _tag, force: true);
    super.dispose();
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
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            _controller.reload(),
            if (_tab == 2) _members.load(),
          ]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: cs.outline),
                  ),
                  child: Text(
                    _controller.project.value.title,
                    textAlign: TextAlign.center,
                    style: tt.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.5),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Información de Proyecto',
                        style: tt.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedTabSwitch(
                      tabs: _tabs,
                      selectedIndex: _tab,
                      onTabSelected: _selectTab,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 16),
                    Obx(() => _tabBody(_controller.project.value)),
                  ],
                ),
              ),
              if (_tab == 0) ...[
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: _openTasks,
                  child: const Text('Ver Tareas'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Al volver del gabinete se relee el proyecto: ahí pudo cambiar el progreso.
  Future<void> _openTasks() async {
    await Get.to(() => TaskBoardPage(project: _controller.project.value));
    if (mounted) _controller.reload();
  }

  void _selectTab(int index) {
    setState(() => _tab = index);
    // Los miembros se leen la primera vez que se abre la pestaña.
    if (index == 2 && !_members.loaded.value) _members.load();
  }

  Widget _tabBody(Project project) {
    switch (_tab) {
      case 0:
        return ProjectProgressTab(progress: project.progress);
      case 2:
        return ProjectMembersTab(
          members: _members.members.toList(),
          isLoading: _members.isLoading.value,
          loaded: _members.loaded.value,
          error: _members.error.value,
          isMe: _members.isMe,
          onRetry: _members.load,
          onOpenMember: (m) => Get.to(() => MemberProfilePage(member: m)),
        );
      default:
        // La pestaña Info. básica llega en su propia rama.
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Disponible pronto.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
    }
  }
}
