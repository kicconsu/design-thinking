import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/trust_indicators.dart';

import '../../domain/models/user_profile.dart';
import '../viewmodels/profile_controller.dart';

/// Detalle de los indicadores de confianza de un perfil.
///
/// Los indicadores se calculan a partir del historial de colaboración: sin
/// historial no se muestra ningún número, y si no se pudieron calcular se
/// muestra el motivo con un botón para reintentar, nunca ceros.
class TrustIndicatorsPage extends StatelessWidget {
  const TrustIndicatorsPage({
    super.key,
    required this.profile,
    this.loading = false,
    this.error,
    this.onRetry,
    this.isOwn = true,
  });

  final UserProfile profile;

  /// Es el perfil de quien mira; cambia la persona gramatical del texto.
  final bool isOwn;

  /// Se están calculando y todavía no hay ninguno que mostrar.
  final bool loading;

  /// Por qué no se pudieron calcular; con [onRetry] ofrece reintentar.
  final String? error;
  final VoidCallback? onRetry;

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
              child: error != null
                  ? Row(
                      key: const Key('trust.page.error'),
                      children: [
                        Icon(Icons.cloud_off, color: cs.error),
                        const SizedBox(width: 14),
                        Expanded(child: Text(error!, style: tt.bodyMedium)),
                        if (onRetry != null)
                          TextButton(
                            key: const Key('trust.page.retry'),
                            onPressed: onRetry,
                            child: const Text('Reintentar'),
                          ),
                      ],
                    )
                  : loading
                  ? const Center(
                      key: Key('trust.page.loading'),
                      child: CircularProgressIndicator(),
                    )
                  : profile.hasTrustHistory
                  ? TrustIndicators(
                      commitmentScore: profile.commitmentScore,
                      onTimeScore: profile.onTimeScore,
                      fulfillmentScore: profile.fulfillmentScore,
                      completedProjectsScore: profile.completedProjectsScore,
                      showTitle: false,
                      showExplanations: true,
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
                          'Aparecen cuando ${isOwn ? 'colabores' : 'colabora'} en un proyecto.',
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

/// El detalle de mis propios indicadores: sigue al [ProfileController], así
/// que se actualiza solo al reintentar o al refrescar el perfil.
class OwnTrustIndicatorsPage extends StatelessWidget {
  const OwnTrustIndicatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return Obx(
      () => TrustIndicatorsPage(
        profile: controller.profileWithTrust ?? const UserProfile(),
        loading:
            controller.isLoadingTrust.value && controller.trust.value == null,
        error: controller.trustError.value,
        onRetry: controller.loadTrust,
      ),
    );
  }
}
