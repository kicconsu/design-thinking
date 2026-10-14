import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/profile/ui/widgets/profile_view.dart';

import '../../domain/models/project_member.dart';
import '../viewmodels/member_profile_controller.dart';

/// Ficha de un miembro del proyecto: su perfil, en solo lectura.
class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key, required this.member});

  final ProjectMember member;

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
    _controller = Get.put(MemberProfileController(widget.member), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<MemberProfileController>(tag: _tag, force: true);
    super.dispose();
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
                ProfileView(name: widget.member.name, profile: profile),
              ],
            );
          }),
        ),
      ),
    );
  }
}
