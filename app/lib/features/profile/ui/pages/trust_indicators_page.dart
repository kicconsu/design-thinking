import 'package:flutter/material.dart';

import 'package:imker/core/widgets/trust_indicators.dart';

import '../../domain/models/user_profile.dart';

/// Detalle de los indicadores de confianza de un perfil.
///
/// Los indicadores se calculan a partir del historial de colaboración (tareas
/// y contribuciones), que todavía no existe: sin historial no se muestra
/// ningún número.
class TrustIndicatorsPage extends StatelessWidget {
  const TrustIndicatorsPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Indicadores de confianza'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outline),
              ),
              child: profile.hasTrustHistory
                  ? TrustIndicators(
                      commitmentScore: profile.commitmentScore,
                      onTimeScore: profile.onTimeScore,
                      fulfillmentScore: profile.fulfillmentScore,
                      completedProjectsScore: profile.completedProjectsScore,
                      showTitle: false,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          size: 40,
                          color: cs.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Todavía no hay indicadores',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Se calculan a partir de la colaboración en proyectos: '
                          'compromiso, entrega a tiempo, tasa de respuesta y '
                          'proyectos completados. Aparecerán cuando haya historial.',
                          style: tt.bodyMedium,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
