import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/features/discover/domain/models/project.dart';
import 'package:f_clean_template/features/discover/ui/pages/collaboration_done_page.dart';

/// Muestra un diálogo de confirmación con estilo Imker antes de enviar la postulación.
Future<void> showConfirmApplicationDialog({
  required BuildContext context,
  required Project project,
  VoidCallback? onConfirmed,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 1.5),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.all(16),
        title: Text(
          '¿Postularte al proyecto?',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estás a punto de postularte a:',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              project.title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirmar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onConfirmed != null) {
                onConfirmed();
              } else {
                Get.to(() => CollaborationDonePage(project: project));
              }
            },
          ),
        ],
      );
    },
  );
}
