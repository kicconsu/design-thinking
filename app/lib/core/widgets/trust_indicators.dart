import 'package:flutter/material.dart';

import 'score_gauge.dart';

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
            ScoreGauge(label: 'Entrega a tiempo', value: onTimeScore),
            ScoreGauge(label: 'Tasa de respuesta', value: responseRateScore),
            ScoreGauge(label: 'Proyectos completados', value: completedProjectsScore),
          ],
        ),
      ],
    );
  }
}
