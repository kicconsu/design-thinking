/// Fuente de la hora actual. Se inyecta donde la lógica depende del reloj para
/// poder fijarlo en las pruebas; en producción es [systemClock].
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();
