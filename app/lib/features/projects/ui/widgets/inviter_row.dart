import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/profile_avatar.dart';
import 'package:imker/features/profile/ui/viewmodels/people_directory.dart';

import '../pages/person_profile_page.dart';

/// «Te invitó [Nombre] ›» en una invitación; tocarlo abre la ficha de quien
/// invitó. El nombre se lee una sola vez por persona (ver [PeopleDirectory]).
class InviterRow extends StatefulWidget {
  const InviterRow({super.key, required this.inviterId});

  final String inviterId;

  @override
  State<InviterRow> createState() => _InviterRowState();
}

class _InviterRowState extends State<InviterRow> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PeopleDirectory>()) {
      Get.find<PeopleDirectory>().load(widget.inviterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PeopleDirectory>()) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final directory = Get.find<PeopleDirectory>();

    return Obx(() {
      final person = directory.summaryOf(widget.inviterId);
      // Hasta que se sepa quién es no se ofrece nada que abrir.
      final name = person?.name;
      return InkWell(
        onTap: name == null
            ? null
            : () => openPersonProfile(userId: widget.inviterId, name: name),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              ProfileAvatar(name: name ?? '?', radius: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name == null ? 'Te invitaron…' : 'Te invitó $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall,
                ),
              ),
              if (name != null)
                Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      );
    });
  }
}
