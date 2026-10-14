import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/profile_avatar.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/routes/app_routes.dart';

import '../viewmodels/profile_controller.dart';
import '../widgets/profile_form_fields.dart';

/// Argumento de ruta: a qué pestaña de Home ir al terminar.
class OnboardingArgs {
  const OnboardingArgs({this.homeTab = 0});

  /// 0 = Descubrir, 2 = Perfil. Un invitado que sube de cuenta ya estaba
  /// dentro de la app y vuelve a su perfil.
  final int homeTab;
}

/// Primeros datos del perfil tras crear la cuenta: carrera, institución,
/// descripción y habilidades. Es omitible: quien no quiera llenarlo entra
/// igual y puede completarlo después desde su perfil.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _form = ProfileFormController();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  int get _homeTab => Get.arguments is OnboardingArgs
      ? (Get.arguments as OnboardingArgs).homeTab
      : 0;

  void _goHome() {
    // HomeViewModel sobrevive entre sesiones: sin esto, una cuenta nueva
    // abriría en la pestaña donde se quedó la anterior.
    if (Get.isRegistered<HomeViewModel>()) {
      Get.find<HomeViewModel>().changePage(_homeTab);
    }
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    // Sin nada escrito, guardar es lo mismo que omitir.
    if (_form.isEmpty) return _goHome();

    final controller = Get.find<ProfileController>();
    final ok = await controller.updateProfile(
      program: _form.programText,
      institution: _form.institutionText,
      bio: _form.bioText,
      skills: _form.skills,
    );
    if (!mounted) return;

    if (ok) {
      _goHome();
    } else {
      Get.snackbar(
        'Error',
        controller.error.value ?? 'No se pudo guardar tu perfil.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = Get.find<AuthenticationController>();
    final controller = Get.find<ProfileController>();
    final firstName = auth.loggedName.trim().split(RegExp(r'\s+')).first;

    // Tras el registro no hay pantalla previa a la que volver.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: cs.primaryContainer,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Center(child: ProfileAvatar(name: auth.loggedName, radius: 40)),
              const SizedBox(height: 16),
              Text(
                firstName.isEmpty ? 'Cuéntanos de ti' : '¡Hola, $firstName!',
                textAlign: TextAlign.center,
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Así te verá el resto de la gente al abrir tu perfil. '
                'Puedes completarlo ahora o más tarde.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
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
                      : const Text('Guardar y continuar'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _goHome, child: const Text('Ahora no')),
            ],
          ),
        ),
      ),
    );
  }
}
