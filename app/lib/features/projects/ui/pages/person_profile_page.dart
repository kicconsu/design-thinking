import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/auth/ui/widgets/account_required_prompt.dart';
import 'package:imker/features/profile/ui/widgets/profile_view.dart';

import '../../domain/models/project_member.dart';
import '../viewmodels/person_profile_controller.dart';
import '../widgets/member_labels.dart';
import 'project_detail_page.dart';

/// Ficha de una persona: su perfil en solo lectura y en qué anda (sus
/// proyectos). Si se abre desde un proyecto del que es miembro ([member] y
/// [projectId]), añade lo que ha hecho ahí, y el creador puede quitarla.
///
/// Se cierra con `true` si se quitó a la persona, para que la lista de
/// miembros se recargue.
class PersonProfilePage extends StatefulWidget {
  const PersonProfilePage({
    super.key,
    required this.userId,
    required this.name,
    this.projectId,
    this.member,
    this.viewerIsCreator = false,
    this.currentUserId,
    this.header,
    this.bottomBar,
  });

  final String userId;
  final String name;
  final String? projectId;
  final ProjectMember? member;
  final bool viewerIsCreator;

  /// Contenido propio de quien abre la ficha (p. ej. los datos de una
  /// solicitud), encima del perfil.
  final Widget? header;

  /// Barra fija al pie (p. ej. aceptar o rechazar una solicitud).
  final Widget? bottomBar;

  /// Sustituye a la sesión real: solo para pruebas.
  final String Function()? currentUserId;

  @override
  State<PersonProfilePage> createState() => _PersonProfilePageState();
}

class _PersonProfilePageState extends State<PersonProfilePage> {
  late final PersonProfileController _controller;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    // Un controlador por ficha: abrir a otra persona no hereda a la anterior.
    _tag = '${widget.userId}#${identityHashCode(this)}';
    _controller = Get.put(
      PersonProfileController(
        userId: widget.userId,
        name: widget.name,
        projectId: widget.projectId,
        member: widget.member,
        viewerIsCreator: widget.viewerIsCreator,
        currentUserId: widget.currentUserId,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<PersonProfileController>(tag: _tag, force: true);
    super.dispose();
  }

  Future<void> _confirmRemove() async {
    final name = widget.name;
    final doing = _controller.tasksDoing.value ?? 0;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('¿Quitar a $name del proyecto?'),
        content: Text(
          [
            if (doing > 0)
              'Sus $doing tareas sin terminar quedarán libres.'
            else
              'No tiene tareas sin terminar.',
            'Se conservan las que ya terminó.',
            'Podrá volver a postular.',
          ].join(' '),
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
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await _controller.remove();
    if (error != null) {
      Get.snackbar('Error', error, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.back(result: true);
    Get.snackbar(
      'Listo',
      '$name ya no está en el proyecto.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: Text(widget.name, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBar: widget.bottomBar,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _controller.load,
          child: Obx(() {
            final profile = _controller.profile.value;
            if (profile == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  if (widget.header != null) widget.header!,
                  const SizedBox(height: 80),
                  if (_controller.error.value != null) ...[
                    Text(
                      _controller.error.value!,
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _controller.load,
                      child: const Text('Reintentar'),
                    ),
                  ] else
                    const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                if (widget.header != null) ...[
                  widget.header!,
                  const SizedBox(height: 16),
                ],
                if (widget.member != null) ...[
                  _InThisProjectCard(controller: _controller),
                  const SizedBox(height: 16),
                ],
                ProfileView(
                  name: widget.name,
                  profile: profile,
                  projects: _controller.projects.value,
                  onOpenProject: (p) =>
                      Get.to(() => ProjectDetailPage(project: p)),
                ),
                if (_controller.canRemove) ...[
                  const SizedBox(height: 32),
                  Obx(
                    () => OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error),
                        minimumSize: const Size.fromHeight(48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: _controller.isRemoving.value
                          ? null
                          : _confirmRemove,
                      icon: _controller.isRemoving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_remove_outlined),
                      label: const Text('Quitar del proyecto'),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Rol, desde cuándo y qué ha hecho esta persona en el proyecto (datos
/// reales: sus tareas).
class _InThisProjectCard extends StatelessWidget {
  const _InThisProjectCard({required this.controller});

  final PersonProfileController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final member = controller.member!;
    final since = memberSinceLabel(member.joinedAt);

    Widget stat(String value, String label) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'En este proyecto',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (since != null)
                        Text(
                          since,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ProjectRoleBadge(role: member.role),
              ],
            ),
          ),
          Obx(() {
            final done = controller.tasksDone.value;
            final doing = controller.tasksDoing.value;
            if (done == null || doing == null) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                border: Border(top: BorderSide(color: cs.outline)),
              ),
              child: Row(
                children: [
                  stat('$done', done == 1 ? 'Terminada' : 'Terminadas'),
                  Container(width: 1, height: 44, color: cs.outline),
                  stat('$doing', 'En curso'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Abre la ficha de una persona. Un invitado no puede leer perfiles ajenos: en
/// su lugar se le pide una cuenta (devuelve null). Devuelve `true` si desde la
/// ficha se quitó a la persona del proyecto.
Future<bool?> openPersonProfile({
  required String userId,
  required String name,
  String? projectId,
  ProjectMember? member,
  bool viewerIsCreator = false,
}) async {
  final auth = Get.find<AuthenticationController>();
  if (!auth.isLogged || auth.isAnonymous) {
    showAccountRequiredPrompt(
      message:
          'Para ver el perfil de otras personas necesitas una cuenta real.',
    );
    return null;
  }
  return Get.to<bool>(
    () => PersonProfilePage(
      userId: userId,
      name: name,
      projectId: projectId,
      member: member,
      viewerIsCreator: viewerIsCreator,
    ),
  );
}
