import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

/// Muestra un snackbar avisando que la acción requiere una cuenta registrada.
/// Incluye un botón para completar la cuenta (si es invitado) o iniciar sesión.
void showAccountRequiredPrompt({required String message}) {
  final auth = Get.find<AuthenticationController>();
  Get.closeCurrentSnackbar();
  Get.snackbar(
    'Cuenta requerida',
    message,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 4),
    margin: const EdgeInsets.all(12),
    backgroundColor: Colors.grey.shade900,
    colorText: Colors.white,
    mainButton: TextButton(
      onPressed: () {
        Get.closeCurrentSnackbar();
        Get.toNamed(
          auth.isAnonymous ? AppRoutes.upgradeAccount : AppRoutes.login,
        );
      },
      child: Text(
        auth.isAnonymous ? 'Completar cuenta' : 'Iniciar sesión',
        style: const TextStyle(
          color: Colors.amberAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

/// Ejecuta [action] solo si el usuario cuenta con una sesión real autenticada.
/// Si es invitado o no está logueado, muestra el aviso de cuenta requerida
/// y cancela la ejecución sin ensuciar los widgets con condicionales manuales.
void guardWithAccount({required String message, required VoidCallback action}) {
  final auth = Get.find<AuthenticationController>();
  if (!auth.isLogged || auth.isAnonymous) {
    showAccountRequiredPrompt(message: message);
    return;
  }
  action();
}

/// Extensión funcional estilo decorador para proteger callbacks en la UI
/// de manera concisa y declarativa: `onPressed: (() => miAccion()).guarded('Mensaje')`
extension ActionGuard on VoidCallback {
  VoidCallback guarded([String? message]) {
    return () => guardWithAccount(
      message: message ?? 'Inicia sesión para realizar esta acción.',
      action: this,
    );
  }
}
