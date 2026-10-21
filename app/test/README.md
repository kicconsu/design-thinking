# Pruebas unitarias y de widget

Unas 560 pruebas, más los 6 flujos de [`integration_test/`](../integration_test/README.md).
Ninguna habla con Roble: usan fuentes de datos en memoria y los dobles de
`test/support/`.

```bash
cd app
flutter test                       # todas
flutter test test/features/tasks   # una carpeta
```

## Tipos

| Tipo | Qué prueba | Archivo | Se escribe con |
|------|------------|---------|----------------|
| Unitaria | Modelos, reglas, repositorios y controladores, sin pantalla | `*_test.dart` | `test()` |
| Widget | Una pantalla o un widget: qué se ve y qué pasa al tocarlo | `*_widget_test.dart` | `testWidgets()` |
| Integración | Un flujo completo de la app | `integration_test/` | `testWidgets()` |

Cada regla se prueba en la capa donde vive; la pantalla solo comprueba que
se vea y que dispare la acción. Un archivo no mezcla `test()` con
`testWidgets()`, y el CI lo revisa.

## Estructura

`test/` replica las capas de `lib/`:

```text
test/
  core/             utilidades y widgets compartidos
  features/<feature>/
    domain/         modelos y reglas
    data/           repositorios y fuentes de datos
    ui/             controladores (viewmodels), páginas y widgets
  support/          dobles y constructores compartidos
```

Features: `auth`, `discover`, `home`, `profile`, `projects`, `tasks`, `trust`.

## Qué cubre cada feature

| Feature | Se prueba |
|---------|-----------|
| `auth` | Validación de registro e inicio de sesión, sesión caducada, pantalla de login |
| `discover` | Filtros por carrera y habilidad, paginación, tarjeta de proyecto |
| `profile` | Carga y guardado del perfil, solo se lee la fila propia, indicadores de confianza en pantalla |
| `projects` | Postulación, invitaciones, aceptar y rechazar solicitudes, salir y quitar miembros, cerrar proyecto, fichas de personas |
| `tasks` | Reservar, checklist, terminar y reabrir, fecha límite, contadores por miembro |
| `trust` | Cálculo de los cuatro indicadores y su lectura desde la base |
| `core` | Etiquetas normalizadas, configuración de logs, barra de navegación |

## Dobles y datos de prueba (`support/`)

- `fake_*_repository.dart`: repositorios configurables (qué devuelven, si
  fallan, qué se les pidió).
- `builders.dart`: `aProject(...)` crea un proyecto con solo los campos que
  importan para la prueba.
- `dummy_data.dart`: filas sembradas para las fuentes en memoria.
- `scripted_project_data_source.dart`: fuente de proyectos que puede fallar o
  responder tarde, para probar reintentos y respuestas atrasadas.

## Convenciones

- Los controles que una prueba necesita tocar se buscan por `Key`
  (`lib/core/utils/app_keys.dart`), no por el texto que se ve.
- El tiempo se inyecta (`Clock`): ninguna prueba depende de la fecha real.
- Una prueba que construya un cliente real de Roble rompe el CI.

## CI

Cada push y cada pull request corren `flutter analyze`, la revisión de la
estructura, las pruebas unitarias, las de widget y la integración en Chrome
(`.github/workflows/`).
