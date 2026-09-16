import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pantallas "Accepted" / "Rejected" del flujo de Figma: confirma la
/// decisión tomada sobre una solicitud de colaboración.
class RequestDecisionResultPage extends StatelessWidget {
  final bool accepted;

  const RequestDecisionResultPage({super.key, required this.accepted});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Imker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: cs.tertiaryContainer,
                child: Icon(
                  accepted ? Icons.emoji_people_outlined : Icons.sentiment_neutral,
                  size: 64,
                  color: cs.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                accepted ? 'Solicitud aceptada' : 'Solicitud rechazada',
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  // Vuelve a la lista de solicitudes: cierra esta pantalla de
                  // resultado y la de detalle del aspirante.
                  Get.back();
                  Get.back();
                },
                child: const Text('Ver más solicitudes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
