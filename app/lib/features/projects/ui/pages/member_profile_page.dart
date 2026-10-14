import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/ui/widgets/profile_view.dart';

import '../../domain/models/project_member.dart';
import '../viewmodels/member_profile_controller.dart';
import '../widgets/member_labels.dart';

/// Ficha de un miembro del proyecto: lo que ha hecho aquí y su perfil, en
/// solo lectura. El creador puede quitar desde aquí a un colaborador.
///
/// Se cierra con `true` si se quitó a la persona, para que la lista de
/// miembros se recargue.
class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({
    super.key,
    required this.member,
    required this.projectId,
    this.viewerIsCreator = false,
    this.currentUserId,
  });

  final ProjectMember member;
  final String projectId;
  final bool viewerIsCreator;

  /// Sustituye a la sesión real: solo para pruebas.
  final String Function()? currentUserId;

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  late final MemberProfileController _controller;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    // Un controlador por ficha: abrir a otra persona no hereda a la anterior.
    _tag = '${widget.member.userId}#${identityHashCode(this)}';
    _controller = Get.put(
      MemberProfileController(
        member: widget.member,
        projectId: widget.projectId,
        viewerIsCreator: widget.viewerIsCreator,
        currentUserId: widget.currentUserId,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<MemberProfileController>(tag: _tag, force: true);
    super.dispose();
  }

  Future<void> _confirmRemove() async {
    final name = widget.member.name;
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
        title: Text(widget.member.name, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        elevation: 0,
      ),
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
                _InThisProjectCard(controller: _controller),
                const SizedBox(height: 16),
                ProfileView(name: widget.member.name, profile: profile),
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

  final MemberProfileController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final member = controller.member;
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
