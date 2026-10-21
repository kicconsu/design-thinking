import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

/// Estado de bienvenida y restricción limpia para invitados en la pestaña de Proyectos.
/// Evita condicionales y filtración de lógica en las vistas internas de proyectos.
class ProjectsGuestGate extends StatelessWidget {
  const ProjectsGuestGate({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = Get.find<AuthenticationController>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_shared_outlined,
                size: 56,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tus proyectos y colaboraciones',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Inicia sesión o completa tu cuenta para gestionar tus proyectos propios, guardados y solicitudes de colaboración.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () => Get.toNamed(
                auth.isAnonymous ? AppRoutes.upgradeAccount : AppRoutes.login,
              ),
              icon: const Icon(Icons.login, size: 20),
              label: Text(
                auth.isAnonymous ? 'Completar mi cuenta' : 'Iniciar sesión',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
