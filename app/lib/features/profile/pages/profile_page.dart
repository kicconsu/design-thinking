import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

/// Pantalla de perfil de usuario.
///
/// Muestra información de la cuenta activa o un banner destacado si el usuario
/// está navegando como invitado, con acceso directo a [AppRoutes.upgradeAccount].
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthenticationController auth = Get.find<AuthenticationController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Obx(() {
        final isLogged = auth.isLogged;
        final isGuest = auth.isAnonymous;
        final name = auth.loggedName.trim().isNotEmpty
            ? auth.loggedName
            : (isGuest ? 'Perfil provisional' : 'Usuario');
        final email = auth.loggedEmail;

        if (!isLogged) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle_outlined, size: 72, color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Inicia sesión para ver tu perfil',
                    style: tt.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.login),
                    child: const Text('Iniciar sesión'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            // ─── Header de usuario ───
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: isGuest ? cs.surfaceContainerHighest : cs.primary,
                child: Icon(
                  isGuest ? Icons.person_outline : Icons.person,
                  size: 44,
                  color: isGuest ? cs.primary : cs.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                name,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            if (email.isNotEmpty && !isGuest) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  email,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ─── Banner de Invitado (amigable, tipo onboarding) ───
            if (isGuest) ...[
              Card(
                elevation: 0,
                color: cs.primaryContainer.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Crea tu perfil completo',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Personaliza tu carrera, añade tus habilidades y postúlate a proyectos para colaborar con otros estudiantes.',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.upgradeAccount),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Completar mi perfil'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ─── Acciones ───
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Configuración'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.snackbar(
                        'Próximamente',
                        'Módulo de configuración en desarrollo.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  if (isGuest)
                    ListTile(
                      leading: Icon(Icons.login, color: cs.primary),
                      title: const Text('Iniciar sesión con cuenta existente'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.offAllNamed(AppRoutes.login),
                    )
                  else
                    ListTile(
                      leading: Icon(Icons.logout, color: cs.error),
                      title: Text(
                        'Cerrar sesión',
                        style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                      ),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cerrar sesión'),
                            content: const Text(
                              '¿Estás seguro de que deseas cerrar sesión?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Salir'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await auth.logOut();
                          Get.offAllNamed(AppRoutes.login);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
