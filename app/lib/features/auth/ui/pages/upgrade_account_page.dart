import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

/// Formulario para que el invitado complete su cuenta (email + contraseña).
///
/// Usa [AuthenticationController.upgradeAccount] que llama a Roble.upgradeAccount.
/// Si el email ya existe → snackbar + opción de ir a login (sin hacer logout).
class UpgradeAccountPage extends StatefulWidget {
  const UpgradeAccountPage({super.key});

  @override
  State<UpgradeAccountPage> createState() => _UpgradeAccountPageState();
}

class _UpgradeAccountPageState extends State<UpgradeAccountPage> with UiLoggy {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthenticationController _auth = Get.find();

  Future<void> _upgrade() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await _auth.upgradeAccount(
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _nameCtrl.text.trim(),
    );

    if (ok) {
      Get.back(); // vuelve al perfil, que ahora muestra la cuenta real
      Get.snackbar(
        '¡Bienvenido!',
        'Tu cuenta ha sido creada.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      // El error ya está en _auth.error. Si es "ya existe", ofrecemos ir a login.
      final isEmailTaken = _auth.error.value.toLowerCase().contains('cuenta');
      Get.snackbar(
        'Error',
        _auth.error.value,
        snackPosition: SnackPosition.BOTTOM,
        mainButton: isEmailTaken
            ? TextButton(
                onPressed: () => Get.offAllNamed(AppRoutes.login),
                child: const Text('Ir a login'),
              )
            : null,
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu cuenta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Guarda tu progreso creando una cuenta.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: (v) =>
                      (v == null || v.length < 7) ? 'Mínimo 7 caracteres' : null,
                ),
                const SizedBox(height: 24),
                Obx(() => _auth.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _upgrade,
                        child: const Text('Crear mi cuenta'),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
