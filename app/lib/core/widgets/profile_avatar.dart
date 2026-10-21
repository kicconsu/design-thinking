import 'package:flutter/material.dart';

/// Avatar de una persona: su foto si hay [imageUrl] y, si no (o si falla la
/// carga), las iniciales del [name] sobre un color estable derivado del nombre.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl = '',
    this.radius = 28,
  });

  final String name;
  final String imageUrl;
  final double radius;

  /// Hasta dos iniciales: primera letra de las dos primeras palabras.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first));
    final text = letters.join().toUpperCase();
    return text.isEmpty ? '?' : text;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = [
      (cs.primary, cs.onPrimary),
      (cs.secondary, cs.onSecondary),
      (cs.tertiary, cs.onTertiary),
    ];
    final hash = name.trim().toLowerCase().codeUnits.fold<int>(
      0,
      (a, c) => a + c,
    );
    final (background, foreground) = palette[hash % palette.length];

    final initials = CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );

    if (imageUrl.trim().isEmpty) return initials;
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      foregroundImage: NetworkImage(imageUrl),
      onForegroundImageError: (_, _) {},
      child: initials.child,
    );
  }
}
