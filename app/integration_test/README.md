# Pruebas de integración

Seis pruebas, una por flujo principal de la app. Ninguna habla con Roble.

| # | Flujo | Archivo |
|---|-------|---------|
| 1 | Descubrir y aplicar a un proyecto | `features/discover/discover_apply_flow_test.dart` |
| 2 | Ver solicitud y aceptar | `features/projects/accept_request_flow_test.dart` |
| 3 | Ver solicitud y rechazar | `features/projects/reject_request_flow_test.dart` |
| 4 | Crear tarea con subtareas | `features/tasks/create_task_flow_test.dart` |
| 5 | Asignarse tarea y avanzar parcialmente | `features/tasks/reserve_task_flow_test.dart` |
| 6 | Terminar tarea asignada | `features/tasks/finish_task_flow_test.dart` |

`app_test.dart` las agrupa y es el archivo que corre el CI.

## Dónde van los archivos

- `integration_test/` va en la raíz de `app/` porque así lo exige
  `flutter drive` (`--target=integration_test/app_test.dart`).
- Dentro, `features/` replica la estructura de `lib/features/`: cada flujo
  queda en la carpeta del feature donde vive su pantalla principal.
- Los dobles de prueba (datasources falsos, sesión falsa, datos sembrados y
  el arranque de la app) están en `integration_test/support/`, no en `lib/`.
  No pueden ir en `test/support/`: con `flutter drive` en web el compilador
  toma `integration_test/` como raíz y no encuentra archivos fuera de ella.

## Cómo se evita Roble

`main()` no se usa: crea el cliente real y apunta al servidor de Uninorte.
`setUpIntegrationEnv` (en `integration_test/support/integration_harness.dart`) arma el
mismo cableado de GetX con dobles:

- `FakeAuthenticationSource`, `FakeProfileDataSource`,
  `FakeProjectDataSource`, `FakeTaskDataSource` y `FakeTrustRepository`
  reemplazan a los datasources de Roble. Guardan filas en memoria con la misma
  forma que las de Roble.
- `FakeRobleDb` solo responde a la app «¿hay sesión y quién es?». No tiene
  ningún método de datos en uso y apunta a `127.0.0.1:1`.
- `expectOnlyTestDoubles()` falla si algún punto de entrada de datos no es un
  doble.

Al terminar un flujo, cada prueba consulta los dobles para comprobar qué quedó
guardado (solicitud aceptada, tarea terminada, progreso del proyecto…).

## Correr en un teléfono o emulador (verla en pantalla)

Es la ruta móvil de las diapositivas: con un dispositivo Android conectado (o un
emulador abierto), desde `app/`:

```bash
flutter test integration_test/app_test.dart -d <id-del-dispositivo> \
  --dart-define=SHOW_TAPS=true --dart-define=STEP_MS=600
```

- `SHOW_TAPS=true` dibuja un anillo rojo donde la prueba toca. Los toques de la
  prueba no los pinta el sistema operativo (la opción «Mostrar toques» de
  Android solo ve dedos reales), así que la app los dibuja.
- `STEP_MS=600` espera 600 ms tras cada toque para poder seguirla a simple vista.
- Sin esos dos parámetros corre a toda velocidad, sin anillos (así corre el CI).

La prueba instala una versión de la app con el mismo identificador que la
normal: al terminar, vuelve a instalar la tuya con `flutter run`.

## Correr en web (como el CI)

1. Instalar el ChromeDriver de la misma versión que Chrome y dejarlo
   escuchando:

   ```bash
   chromedriver --port=4444
   ```

2. En otra terminal, dentro de `app/`:

   ```bash
   flutter drive \
     --driver=test_driver/integration_test.dart \
     --target=integration_test/app_test.dart \
     -d chrome
   ```

   No se puede apuntar `--target` a un solo archivo de `features/`: el
   compilador toma la carpeta del target como raíz y no vería `support/`.

Sin navegador (como en el CI): `-d web-server --browser-name=chrome --headless`.
