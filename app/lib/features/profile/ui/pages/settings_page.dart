import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

import 'edit_profile_page.dart';

/// Detalles de la cuenta (solo lectura) y ajustes: editar perfil,
/// configuración y cerrar sesión.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
    final tt = Theme.of(context).textTheme;
    final auth = Get.find<AuthenticationController>();

    // Material (no un Container con color): el ListTile pinta su fondo y su
    // efecto de toque sobre el Material más cercano.
    Widget group(List<Widget> tiles) => Material(
      color: cs.surface,
      shape: Border.all(color: cs.outline),
      child: Column(children: tiles),
    );

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Ajustes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Detalles',
              style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CORREO',
                          style: tt.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(auth.loggedEmail, style: tt.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ajustes',
              style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            group([
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Editar perfil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.off(() => const EditProfilePage()),
              ),
              Divider(height: 1, color: cs.outline),
              const ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Configuración'),
                subtitle: Text('Próximamente'),
                enabled: false,
              ),
            ]),
            const SizedBox(height: 20),
            group([
              ListTile(
                leading: Icon(Icons.logout, color: cs.error),
                title: Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: cs.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: _confirmLogout,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
