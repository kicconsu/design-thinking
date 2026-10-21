# Pruebas de integración

Seis pruebas, una por flujo principal de la app. Cada una abre la app completa,
toca las pantallas como lo haría una persona y comprueba al final qué quedó
guardado. Ninguna habla con Roble.

| # | Flujo | Qué comprueba | Archivo |
|---|-------|---------------|---------|
| 1 | Descubrir y aplicar a un proyecto | Queda una solicitud pendiente y el detalle ya no ofrece postular | `features/discover/discover_apply_flow_test.dart` |
| 2 | Ver una solicitud y aceptarla | La solicitud queda aceptada, quien la envió es miembro y sale de la lista | `features/projects/accept_request_flow_test.dart` |
| 3 | Ver una solicitud y rechazarla | La solicitud queda rechazada, no hay nuevo miembro y sale de la lista | `features/projects/reject_request_flow_test.dart` |
| 4 | Crear una tarea con subtareas | La tarea aparece en «Pendientes», se reserva y guarda sus tres subtareas | `features/tasks/create_task_flow_test.dart` |
| 5 | Reservar una tarea y avanzar | Pasa a «En progreso» y un avance parcial no la termina | `features/tasks/reserve_task_flow_test.dart` |
| 6 | Terminar la tarea | Queda terminada con hora de cierre y el proyecto marca 100 % | `features/tasks/finish_task_flow_test.dart` |

`app_test.dart` las agrupa y es el archivo que corre el CI.

## Estructura

```text
integration_test/
  app_test.dart       agrupa los seis flujos
  features/           un archivo por flujo, en la carpeta de su feature
  support/            dobles de datos, sesión falsa, datos sembrados y arranque
```

La carpeta está en la raíz de `app/` porque `flutter drive` lo exige. Los
dobles viven dentro de ella y no en `test/support/`: en web el compilador toma
`integration_test/` como raíz y no encuentra archivos fuera.

## Cómo se evita Roble

`main()` no se usa, porque crea el cliente real. `setUpIntegrationEnv`
(`support/integration_harness.dart`) arma el mismo cableado de GetX con dobles:

- `FakeAuthenticationSource`, `FakeProfileDataSource`,
  `FakeProjectDataSource`, `FakeTaskDataSource` y `FakeTrustRepository`
  reemplazan a las fuentes de Roble y guardan filas en memoria con su misma
  forma.
- `FakeRobleDb` solo responde si hay sesión y quién es.
- `expectOnlyTestDoubles()` falla si algún punto de entrada de datos no es un
  doble.

## Correr en web (Como CI)

1. Dejar el ChromeDriver escuchando en una terminal:
```bash
   chromedriver --port=4444
```
 
2. En otra terminal, dentro de `app/` (en una sola línea, que también sirve
   en PowerShell):
```bash
   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server --browser-name=chrome --no-headless
```
 
   `--no-headless` abre la ventana de Chrome para ver la app. Sin esa opción
   corre sin ventana, igual que el CI. Si todo sale bien termina con
   `All tests passed.`

## Correr en un teléfono o emulador

Con un dispositivo Android conectado, desde `app/`:

```bash
flutter test integration_test/app_test.dart -d <id-del-dispositivo> \
  --dart-define=SHOW_TAPS=true --dart-define=STEP_MS=600
```

- `SHOW_TAPS=true` dibuja un anillo rojo donde la prueba toca.
- `STEP_MS=600` espera 600 ms tras cada toque para seguirla a simple vista.
- Sin esos parámetros corre a toda velocidad, sin anillos.

Instala una compilación de prueba con el mismo identificador que la app
normal; después se vuelve a instalar con `flutter run`.
