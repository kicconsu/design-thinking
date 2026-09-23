import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

/// Menú que se abre con el ícono de hamburguesa en la pestaña de Perfil.
/// Es un [Drawer] estándar de Flutter: entra deslizándose desde el borde
/// izquierdo con la transición nativa del framework.
class ProfileSettingsDrawer extends StatelessWidget {
  const ProfileSettingsDrawer({super.key});

  Future<void> _confirmLogout() async {
    final auth = Get.find<AuthenticationController>();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.logOut();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: cs.primaryContainer,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                Get.snackbar(
                  'Próximamente',
                  'Módulo de configuración en desarrollo.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: cs.error),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _confirmLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
