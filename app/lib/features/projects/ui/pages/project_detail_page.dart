import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/widgets/account_required_prompt.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/models/project_relation.dart';
import 'package:imker/features/projects/ui/pages/person_profile_page.dart';
import 'package:imker/features/projects/ui/viewmodels/project_members_controller.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/widgets/closed_project_banner.dart';
import 'package:imker/features/projects/ui/widgets/project_members_tab.dart';
import 'package:imker/features/projects/ui/widgets/confirm_application_dialog.dart';
import 'package:imker/core/utils/app_keys.dart';

/// Pantalla de detalle de proyecto: permite ver la descripción completa,
/// integrantes, habilidades requeridas y postularse al proyecto.
class ProjectDetailPage extends StatelessWidget {
  final Project? project;

  const ProjectDetailPage({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    final effectiveProject =
        project ?? (Get.arguments is Project ? Get.arguments as Project : null);
    if (effectiveProject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proyecto')),
        body: const Center(child: Text('No se especificó un proyecto')),
      );
    }
    final projectItem = effectiveProject;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userProjectsController = Get.find<UserProjectsController>();

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Imker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(projectItem.title, style: tt.headlineSmall),
            if (projectItem.imageUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _ProjectCover(url: projectItem.imageUrl),
            ],
            const SizedBox(height: 20),
            _Section(
              title: 'Descripción',
              child: Text(projectItem.description, style: tt.bodyMedium),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Integrantes',
              child: _MembersSection(projectId: projectItem.id),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Habilidades',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscamos personas con las siguientes habilidades:',
                    style: tt.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  ...projectItem.skills.map(
                    (s) => Text('• $s', style: tt.bodyMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Obx(() {
              final relation = userProjectsController.relationOf(projectItem);

              // Qué decir según la relación; solo guardado/nada permite postular.
              String? banner;
              switch (relation) {
                case ProjectRelation.owner:
                  banner = 'Eres el creador de este proyecto';
                case ProjectRelation.active:
                  banner = 'Ya colaboras en este proyecto';
                case ProjectRelation.invited:
                  banner = 'Te invitaron: respóndela en Proyectos → Otros proyectos → Invitaciones';
                case ProjectRelation.pending:
                  banner = 'Postulación pendiente de respuesta';
                case ProjectRelation.saved:
                case ProjectRelation.none:
                  banner = null;
              }

              if (banner != null) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    border: Border.all(color: cs.outline),
                  ),
                  child: Center(
                    child: Text(
                      banner,
                      textAlign: TextAlign.center,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                );
              }

              // Cerrado: ya no recibe solicitudes, no hay a qué postular.
              if (!projectItem.isOpen) return const ClosedProjectBanner();
              return FilledButton.icon(
                key: AppKeys.applyToProject,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed:
                    (() => showConfirmApplicationDialog(
                      context: context,
                      project: projectItem,
                    )).guarded(
                      'Para postularte a un proyecto necesitas una cuenta real.',
                    ),
                icon: const Icon(Icons.volunteer_activism_outlined),
                label: const Text('¡Quiero colaborar!'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Quién está en el proyecto, con su papel; tocar a alguien abre su ficha. Un
/// controlador por entrada, para no heredar los miembros de otro proyecto.
class _MembersSection extends StatefulWidget {
  const _MembersSection({required this.projectId});

  final String projectId;

  @override
  State<_MembersSection> createState() => _MembersSectionState();
}

class _MembersSectionState extends State<_MembersSection> {
  late final ProjectMembersController _members;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = '${widget.projectId}#${identityHashCode(this)}';
    _members = Get.put(ProjectMembersController(widget.projectId), tag: _tag)
      ..load();
  }

  @override
  void dispose() {
    Get.delete<ProjectMembersController>(tag: _tag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ProjectMembersTab(
        members: _members.members.toList(),
        isLoading: _members.isLoading.value,
        loaded: _members.loaded.value,
        error: _members.error.value,
        isMe: _members.isMe,
        onRetry: _members.load,
        onOpenMember: (m) => openPersonProfile(
          userId: m.userId,
          name: m.name,
          projectId: widget.projectId,
          member: m,
        ),
      ),
    );
  }
}

/// Imagen de portada del proyecto entre el título y la descripción.
class _ProjectCover extends StatelessWidget {
  final String url;

  const _ProjectCover({required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Divider(color: cs.outline),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
