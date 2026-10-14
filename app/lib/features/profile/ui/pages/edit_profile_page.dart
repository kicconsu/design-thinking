import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/operation_done_page.dart';
import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';

import '../viewmodels/profile_controller.dart';
import '../widgets/profile_form_fields.dart';

/// Pantalla "Edit-Profile" del flujo de Figma: edita carrera, resumen y
/// habilidades del propio perfil.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final ProfileFormController _form;

  @override
  void initState() {
    super.initState();
    _form = ProfileFormController(Get.find<ProfileController>().profile);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = Get.find<ProfileController>();
    final ok = await controller.updateProfile(
      program: _form.programText,
      institution: _form.institutionText,
      bio: _form.bioText,
      skills: _form.skills,
    );

    if (!mounted) return;

    if (ok) {
      Get.off(
        () => OperationDonePage(
          title: '¡Listo!',
          text: 'Hemos actualizado tu perfil.',
          image: const Icon(Icons.emoji_people_outlined, size: 64),
          buttonText: 'Volver a la aplicación',
          onButtonPressed: () {
            // Vuelve a la pantalla principal y se asegura de dejar
            // seleccionada la pestaña de Perfil, no la de Descubrir.
            Get.until((route) => route.isFirst);
            Get.find<HomeViewModel>().changePage(2);
          },
        ),
      );
    } else {
      Get.snackbar(
        'Error',
        controller.error.value ?? 'No se pudo actualizar tu perfil.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthenticationController>();
    final controller = Get.find<ProfileController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final profile = controller.profile;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Imker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Mi Perfil',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.tertiaryContainer,
                  child: Icon(
                    Icons.person,
                    color: cs.onTertiaryContainer,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.loggedName,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profile != null && profile.academicInfo.isNotEmpty)
                        Text(profile.academicInfo, style: tt.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Las pestañas se mantienen por consistencia visual con el
            // perfil de lectura; solo "Perfil General" es editable aquí.
            SegmentedTabSwitch(
              tabs: const ['Perfil General', 'Proyectos'],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
            const SizedBox(height: 16),
            ProfileFormFields(form: _form),
            const SizedBox(height: 32),
            Obx(
              () => FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: controller.isSaving.value ? null : _save,
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
