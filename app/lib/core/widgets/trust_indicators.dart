import 'package:flutter/material.dart';

/// Sección de "Indicadores de confianza": el índice general de compromiso
/// más los tres medidores circulares (entrega a tiempo, tasa de respuesta,
/// proyectos completados).
///
/// Se usa tanto en el detalle de una solicitud de colaboración
/// ([ApplicantDetailPage]) como en el propio perfil del usuario
/// ([ProfilePage]), así que vive en core/widgets en vez de duplicarse.
class TrustIndicators extends StatelessWidget {
  final int commitmentScore;
  final int onTimeScore;
  final int responseRateScore;
  final int completedProjectsScore;

  const TrustIndicators({
    super.key,
    required this.commitmentScore,
    required this.onTimeScore,
    required this.responseRateScore,
    required this.completedProjectsScore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicadores de confianza',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text('Índice general de compromiso', style: tt.bodyMedium),
            ),
            Text(
              '$commitmentScore%',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          child: LinearProgressIndicator(
            value: commitmentScore / 100,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreGauge(label: 'Entrega a tiempo', value: onTimeScore, cs: cs, tt: tt),
            _ScoreGauge(label: 'Tasa de respuesta', value: responseRateScore, cs: cs, tt: tt),
            _ScoreGauge(
              label: 'Proyectos completados',
              value: completedProjectsScore,
              cs: cs,
              tt: tt,
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  final String label;
  final int value;
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
