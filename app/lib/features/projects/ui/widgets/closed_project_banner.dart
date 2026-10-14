import 'package:flutter/material.dart';

/// Aviso de que un proyecto está cerrado: ya no recibe solicitudes ni
/// invitaciones.
class ClosedProjectBanner extends StatelessWidget {
  const ClosedProjectBanner({
    super.key,
    this.message =
        'Proyecto cerrado: ya no recibe solicitudes ni invitaciones.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
