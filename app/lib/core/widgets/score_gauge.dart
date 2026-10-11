import 'package:flutter/material.dart';

/// Medidor circular con el porcentaje al centro y una etiqueta debajo.
///
/// Se usa en los indicadores de confianza y en el progreso de un proyecto.
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.label, required this.value});

  final String label;

  /// Porcentaje de 0 a 100.
  final int value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: 90,
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                ),
                Text('$value%', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: tt.bodySmall),
        ],
      ),
    );
  }
}
