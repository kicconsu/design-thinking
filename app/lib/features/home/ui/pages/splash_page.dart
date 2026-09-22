import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/routes/app_routes.dart';

/// Pantalla de inicio: restaura la sesión de Roble y redirige al destino
/// correcto sin mostrar parpadeos de UI.
///
/// [AuthenticationController.onInit] llama a [_restoreSession] en background.
/// Esta pantalla se suscribe al estado reactivo y redirige en cuanto cambia.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final auth = Get.find<AuthenticationController>();

    // Esperar a que el controller termine de restaurar la sesión.
    // isLoading baja a false cuando _restoreSession() completa.
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return auth.isLoading;
    });

    if (auth.isLogged) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primaryContainer,
      body: Center(
        child: CircularProgressIndicator(color: cs.primary),
      ),
    );
  }
}
