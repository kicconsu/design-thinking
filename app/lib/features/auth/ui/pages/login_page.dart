import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'package:imker/core/roble/roble_config.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

/// Página de login. Toda la navegación usa rutas GetX nombradas.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with UiLoggy {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthenticationController _auth = Get.find();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await _auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.snackbar(
        'Error',
        _auth.error.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _loginAsGuest() async {
    final ok = await _auth.signInAsGuest();
    if (ok) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.snackbar(
        'Error',
        _auth.error.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _loginDev() async {
    FocusScope.of(context).unfocus();
    final ok = await _auth.quickDevLogin();
    if (ok) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.snackbar(
        'Error',
        _auth.error.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El teclado se come parte de la pantalla: el LayoutBuilder da la altura
    // libre real y el SingleChildScrollView la usa como mínimo, de modo que
    // el formulario se centra cuando hay espacio y se desliza cuando no.
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Imker',
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inicia sesión para continuar',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Correo inválido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                          ),
                          validator: (v) => (v == null || v.length < 7)
                              ? 'Mínimo 7 caracteres'
                              : null,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 24),
                        Obx(
                          () => _auth.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : FilledButton(
                                  onPressed: _login,
                                  child: const Text('Entrar'),
                                ),
                        ),
                        // Aquí caen los errores que no nacen de un toque en el
                        // botón: la sesión que se cayó, por ejemplo.
                        Obx(
                          () => _auth.error.value.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    _auth.error.value,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.register),
                          child: const Text('Crear cuenta'),
                        ),
                        const Divider(height: 32),
                        OutlinedButton(
                          onPressed: _loginAsGuest,
                          child: const Text('Entrar como invitado'),
                        ),
                        // Las credenciales de prueba viven en el servidor real:
                        // el botón sólo aparece si además se pidió a propósito.
                        if (kDebugMode && RobleConfig.devLoginEnabled) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loginDev,
                            icon: const Icon(
                              Icons.bug_report_outlined,
                              size: 16,
                            ),
                            label: const Text('Acceso rápido Dev'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
