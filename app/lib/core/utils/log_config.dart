import 'package:loggy/loggy.dart';

/// Nivel de log según el modo de compilación.
///
/// En release solo se registran los errores: los mensajes de nivel `debug`
/// llevan cargas completas (`createTask payload: …`) y correos, que no deben
/// quedar en el log de un dispositivo de usuario.
LogOptions logOptionsFor({required bool release}) =>
    release ? const LogOptions(LogLevel.error) : const LogOptions(LogLevel.all);
