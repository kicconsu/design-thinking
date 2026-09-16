import 'package:flutter/material.dart';

class RequestsButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final ColorScheme cs;

  const RequestsButton({
    required this.count,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: cs.secondaryContainer),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline, size: 16, color: cs.onSecondaryContainer),
            const SizedBox(width: 4),
            Text(
              '$count solicitud${count == 1 ? '' : 'es'}',
              style: TextStyle(color: cs.onSecondaryContainer, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}