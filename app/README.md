# Imker

App móvil (Flutter, Android) para que estudiantes de la Universidad del Norte
descubran proyectos colaborativos, se postulen, formen equipo y gestionen
tareas. El backend es [Roble](https://roble.openlab.uninorte.edu.co); el estado
se maneja con GetX.

## Ejecutar

```bash
cd app
flutter pub get
flutter run
```

Acceso rápido para desarrollo (solo en debug; las credenciales no viven en el
código):

```bash
flutter run --dart-define=DEV_LOGIN=true \
  --dart-define=DEV_EMAIL=<correo> --dart-define=DEV_PASSWORD=<clave>
```

## Pruebas y análisis

```bash
flutter analyze
flutter test                          # unitarias y de widget
flutter test integration_test/app_test.dart -d <dispositivo>   # flujos completos
```

| Qué | Dónde | Detalle |
|-----|-------|---------|
| Unitarias y de widget | `test/` | [test/README.md](test/README.md) |
| Integración (6 flujos) | `integration_test/` | [integration_test/README.md](integration_test/README.md) |

Ninguna prueba toca Roble: usan fuentes de datos en memoria y dobles. El CI
(`.github/workflows/`) corre el análisis y todas las pruebas en cada push y
pull request.

## Estructura

```text
lib/
  core/      Roble, tema, utilidades y widgets compartidos
  features/  auth, discover, home, profile, projects, tasks, trust
    <feature>/
      domain/  modelos y contratos de repositorio
      data/    fuentes de datos (Roble o memoria) y repositorios
      ui/      páginas, widgets y controladores (viewmodels)
  routes/    rutas de navegación
test/              replica las capas de lib/
integration_test/  flujos completos con dobles de datos
```

Cada feature registra sus dependencias en su `*_dependencies.dart`; la vista
habla con un controlador y este con un repositorio (interfaz en `domain`).
[CODEBASE_INDEX.md](CODEBASE_INDEX.md) describe cada feature.

## Entrega

- Identificador de la app: `co.edu.uninorte.imker`; versión en `pubspec.yaml`.
- `flutter build apk --release` genera el APK. Hoy el release se firma con la
  llave de debug; la firma definitiva está pendiente.
- Consultas guardadas de Roble y modelo de datos: [`../docs/db`](../docs/db).
