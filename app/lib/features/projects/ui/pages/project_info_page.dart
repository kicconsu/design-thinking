import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/imker_app_bar.dart';
import 'package:imker/core/widgets/imker_bottom_nav_bar.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_member.dart';
import 'package:imker/features/projects/ui/pages/person_profile_page.dart';
import 'package:imker/features/projects/ui/viewmodels/project_basic_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/project_info_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/project_members_controller.dart';
import 'package:imker/features/projects/ui/widgets/project_basic_info_tab.dart';
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
  late final ProjectBasicInfoController _basic;
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
    _basic = Get.put(ProjectBasicInfoController(_controller), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<ProjectInfoController>(tag: _tag, force: true);
    Get.delete<ProjectMembersController>(tag: _tag, force: true);
    Get.delete<ProjectBasicInfoController>(tag: _tag, force: true);
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
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: cs.outline),
                  ),
                  // Título centrado entre dos huecos iguales; en uno va el
                  // menú. El creador no puede salir: sin menú no hay nada que
                  // ofrecerle (aquí irá «Cerrar proyecto»).
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          _controller.project.value.title,
                          textAlign: TextAlign.center,
                          style: tt.headlineMedium,
                        ),
                      ),
                      if (_isCreator)
                        const SizedBox(width: 48)
                      else
                        PopupMenuButton<String>(
                          tooltip: 'Más acciones',
                          onSelected: (_) => _confirmLeave(),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'leave',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: cs.error, size: 20),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Salir del proyecto',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: cs.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
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

  /// Quien creó el proyecto: puede quitar gente y no puede salir.
  bool get _isCreator {
    final owner = _controller.project.value.owner;
    if (owner.isNotEmpty && owner == _members.currentUserId) return true;
    return widget.currentUserId == null &&
        Get.isRegistered<UserProjectsController>() &&
        Get.find<UserProjectsController>().isOwner(_controller.project.value);
  }

  Future<void> _confirmLeave() async {
    final title = _controller.project.value.title;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('¿Salir de «$title»?'),
        content: const Text(
          'Dejarás de ser parte del proyecto y tus tareas sin terminar '
          'quedarán libres. Se conservan las que ya terminaste. Para volver '
          'tendrás que postular de nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await _members.leave();
    if (error != null) {
      Get.snackbar('Error', error, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.back();
    Get.snackbar(
      'Listo',
      'Saliste de «$title».',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Si en la ficha se quitó a alguien, la lista se recarga al volver.
  Future<void> _openMember(ProjectMember member) async {
    final removed = await Get.to<bool>(
      () => PersonProfilePage(
        userId: member.userId,
        name: member.name,
        member: member,
        projectId: widget.project.id,
        viewerIsCreator: _isCreator,
        currentUserId: widget.currentUserId,
      ),
    );
    if (removed == true && mounted) _members.load();
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
          onOpenMember: _openMember,
          canManage: _isCreator,
        );
      default:
        return ProjectBasicInfoTab(
          title: _basic.title,
          description: _basic.description,
          jobs: _basic.jobs,
          skills: _basic.skills,
          onJobsChanged: (v) => _basic.jobs = v,
          onSkillsChanged: (v) => _basic.skills = v,
          canEdit: _basic.canEdit,
          isSaving: _basic.isSaving.value,
          onSave: _saveBasicInfo,
        );
    }
  }

  Future<void> _saveBasicInfo() async {
    final error = await _basic.save();
    Get.snackbar(
      error == null ? 'Listo' : 'No se pudo guardar',
      error ?? 'Los cambios del proyecto se guardaron.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
