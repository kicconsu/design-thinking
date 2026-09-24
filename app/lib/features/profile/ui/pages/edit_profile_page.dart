import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/operation_done_page.dart';
import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import '../viewmodels/profile_controller.dart';

/// Pantalla "Edit-Profile" del flujo de Figma: edita el resumen y las
/// habilidades del propio perfil.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _bioController = TextEditingController();
  final _newSkillController = TextEditingController();
  late List<String> _skills;

  @override
  void initState() {
    super.initState();
    final profile = Get.find<ProfileController>().profile;
    _bioController.text = profile?.bio ?? '';
    _skills = List<String>.from(profile?.skills ?? const []);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _newSkillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final value = _newSkillController.text.trim();
    if (value.isEmpty) return;
    final alreadyExists = _skills.any((s) => s.toLowerCase() == value.toLowerCase());
    if (alreadyExists) {
      _newSkillController.clear();
      return;
    }
    setState(() {
      _skills.add(value);
      _newSkillController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _save() async {
    final controller = Get.find<ProfileController>();
    final ok = await controller.updateProfile(bio: _bioController.text.trim(), skills: _skills);

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
            Text('Mi Perfil', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.tertiaryContainer,
                  child: Icon(Icons.person, color: cs.onTertiaryContainer, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.loggedName,
                        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
            Text('Sobre ti', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.surface,
                hintText: 'Cuéntale al resto de estudiantes sobre ti...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: cs.outline),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Habilidades', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSkillController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cs.surface,
                      hintText: 'p. ej. Pandas, DuckDB...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: cs.outline),
                      ),
                    ),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: _addSkill,
                  child: const Text('Aceptar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map(
                    (s) => Chip(
                      label: Text(s),
                      backgroundColor: cs.secondaryContainer,
                      labelStyle: TextStyle(color: cs.onSecondaryContainer),
                      deleteIcon: Icon(Icons.close, size: 16, color: cs.onSecondaryContainer),
                      onDeleted: () => _removeSkill(s),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: cs.outline),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            Obx(
              () => FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
