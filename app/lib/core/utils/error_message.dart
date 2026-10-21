import 'package:roble/roble.dart';

/// Convierte una excepción en un mensaje comprensible para el usuario final.
String errorMessage(Object error, {String? fallback}) {
  if (error is RobleApiHttpException) {
    if (error.statusCode == 429) {
      return 'Demasiados intentos seguidos. Por seguridad, espera un momento antes de volver a intentar.';
    }
    if (error.statusCode == 409) {
      return 'Este correo ya tiene una cuenta registrada.';
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Credenciales inválidas o no autorizadas.';
    }
    return error.message.isNotEmpty ? error.message : (fallback ?? 'Error en el servidor (${error.statusCode}).');
  }

  if (error is RobleApiTimeoutException) {
    return 'El servidor de Roble está tardando en responder. Revisa tu conexión o intenta en unos momentos.';
  }

  if (error is RobleApiNetworkException) {
    return 'Sin conexión a internet. Revisa tu red.';
  }

  final str = error.toString();
  if (str.contains('429') || str.toLowerCase().contains('too many requests')) {
    return 'Demasiados intentos seguidos. Espera un momento antes de volver a intentar.';
  }
  if (str.toLowerCase().contains('already exists') || str.toLowerCase().contains('ya tiene cuenta')) {
    return 'Este correo ya está registrado.';
  }

  return fallback ?? str;
}
