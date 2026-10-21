import 'package:flutter/material.dart';

/// Sección de "Indicadores de confianza": el índice general de compromiso
/// más los tres medidores circulares (entrega a tiempo, cumplimiento,
/// proyectos completados). Un valor nulo es "sin datos" y se muestra como «—».
///
/// Se usa tanto en el detalle de una solicitud de colaboración
/// ([ApplicantDetailPage]) como en el propio perfil del usuario
/// ([ProfilePage]), así que vive en core/widgets en vez de duplicarse.
class TrustIndicators extends StatelessWidget {
  final int? commitmentScore;
  final int? onTimeScore;
  final int? fulfillmentScore;
  final int? completedProjectsScore;

  /// Falso cuando quien lo usa ya pone su propio título (p. ej. una tarjeta).
  final bool showTitle;

  /// Añade bajo los medidores una línea por indicador que dice qué mide.
  final bool showExplanations;

  const TrustIndicators({
    super.key,
    required this.commitmentScore,
    required this.onTimeScore,
    required this.fulfillmentScore,
    required this.completedProjectsScore,
    this.showTitle = true,
    this.showExplanations = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Indicadores de confianza',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: Text('Índice general de compromiso', style: tt.bodyMedium),
            ),
            Text(
              commitmentScore == null ? '—' : '$commitmentScore%',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (showExplanations)
          Text(
            'Promedio de los indicadores con datos.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        const SizedBox(height: 4),
        ClipRRect(
          child: LinearProgressIndicator(
            value: (commitmentScore ?? 0) / 100,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreGauge(
              label: 'Entrega a tiempo',
              value: onTimeScore,
              cs: cs,
              tt: tt,
            ),
            _ScoreGauge(
              label: 'Cumplimiento',
              value: fulfillmentScore,
              cs: cs,
              tt: tt,
            ),
            _ScoreGauge(
              label: 'Proyectos completados',
              value: completedProjectsScore,
              cs: cs,
              tt: tt,
            ),
          ],
        ),
        if (showExplanations) ...[
          const SizedBox(height: 20),
          _Explanation(
            label: 'Cumplimiento',
            text: 'De las tareas que tomó, cuántas terminó.',
            tt: tt,
            cs: cs,
          ),
          _Explanation(
            label: 'Entrega a tiempo',
            text: 'De las tareas con fecha límite, cuántas entregó a tiempo.',
            tt: tt,
            cs: cs,
          ),
          _Explanation(
            label: 'Proyectos completados',
            text:
                'De los proyectos en que participó, cuántos llegaron al 100 %.',
            tt: tt,
            cs: cs,
          ),
        ],
      ],
    );
  }
}

class _Explanation extends StatelessWidget {
  final String label;
  final String text;
  final TextTheme tt;
  final ColorScheme cs;

  const _Explanation({
    required this.label,
    required this.text,
    required this.tt,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(text, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  final String label;
  final int? value;
  final ColorScheme cs;
  final TextTheme tt;

  const _ScoreGauge({
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
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
                  value: (value ?? 0) / 100,
                  strokeWidth: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                ),
                Text(
                  value == null ? '—' : '$value%',
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: tt.bodySmall),
          if (value == null)
            Text(
              'Sin datos aún',
              textAlign: TextAlign.center,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
