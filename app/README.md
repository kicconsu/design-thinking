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
flutter test
```

Las pruebas nunca tocan Roble: usan fuentes de datos en memoria y los
datos de `test/support/`.

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
test/        replica las capas de lib/; dobles compartidos en test/support/
```

Cada feature registra sus dependencias en su `*_dependencies.dart`; la vista
habla con un controlador y este con un repositorio (interfaz en `domain`).

## Entrega

- Identificador de la app: `co.edu.uninorte.imker`; versión en `pubspec.yaml`.
- `flutter build apk --release` genera el APK. Hoy el release se firma con la
  llave de debug; la firma definitiva está pendiente.
- Consultas guardadas de Roble y modelo de datos: [`../docs/db`](../docs/db).
