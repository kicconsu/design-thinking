# Codebase Index

## Overview

`imker` es una app Flutter organizada por feature con una arquitectura
pragmática Clean / MVVM. GetX aporta la inyección de dependencias, la
navegación por rutas nombradas y el estado reactivo.

El backend es **Roble** (`roble: ^1.12.0`): el paquete maneja tokens, cabeceras,
refresco automático y persistencia en `flutter_secure_storage`. La app no toca
tokens ni construye peticiones HTTP a mano.

## Runtime entry y composición

- [`lib/main.dart`](lib/main.dart) — Punto de entrada. Registra `RobleClient`
  (sólo si hay contrato), `registerProfileData()`, `registerAuth()`,
  `registerProjects()` y arranca `MyApp`.
- [`lib/core/roble/roble_config.dart`](lib/core/roble/roble_config.dart) —
  `baseUrl`, `contractId` y el flag `DEV_LOGIN`, todos por `--dart-define`.
- [`lib/core/roble/roble_client.dart`](lib/core/roble/roble_client.dart) — Un
  único cliente por app. Expone `currentUserId` (el `sub` del JWT, que es el
  `_owner` de las filas), `matchesUser`, los nombres de tabla y
  `readPublicOrPrivate`.
- [`lib/routes/app_pages.dart`](lib/routes/app_pages.dart) — Tabla de rutas y
  bindings por pantalla.
- [`lib/core/utils/error_message.dart`](lib/core/utils/error_message.dart) —
  Excepciones de Roble a mensajes presentables.

Grafo de dependencias (auth):

```text
AuthenticationController
  -> IAuthRepository
    -> AuthRepository          (encadena register -> login)
      -> IAuthenticationSource
        -> AuthenticationSourceService  (Roble)  o  DummyAuthSource (sin contrato)
          -> RobleClient.db : RobleApiDataBase
  -> IProfileRepository        (garantiza la fila `profile`, vía Get.find)
```

Grafo de dependencias (perfil):

```text
ProfileController
  -> IProfileRepository
    -> ProfileRepository       (traduce RobleApi* a ProfileFailure)
      -> IProfileDataSource
        -> RobleProfileDataSource  o  InMemoryProfileDataSource
          -> RobleClient
```

## Authentication feature

### Domain

- [`lib/features/auth/domain/models/authentication_user.dart`](lib/features/auth/domain/models/authentication_user.dart) —
  `AuthenticationUser` (`id` es el `userId` de Roble, no el id de la fila).
- [`lib/features/auth/domain/repositories/i_auth_repository.dart`](lib/features/auth/domain/repositories/i_auth_repository.dart) —
  Contrato que ve la UI.

### Data

- [`lib/features/auth/data/datasources/remote/i_authentication_source.dart`](lib/features/auth/data/datasources/remote/i_authentication_source.dart) —
  Contrato del proveedor de auth: credenciales, sesión y `sessionExpired`.
- [`lib/features/auth/data/datasources/remote/roble_auth_data_source.dart`](lib/features/auth/data/datasources/remote/roble_auth_data_source.dart) —
  Implementación real contra Roble. **No toca tablas de negocio**: si la sesión
  necesita una fila en `profile`, la pide `AuthenticationController` a
  `features/profile`.
- [`lib/features/auth/data/repositories/auth_repository.dart`](lib/features/auth/data/repositories/auth_repository.dart) —
  Delegación fina; el registro encadena `register` + `login`.
- [`lib/core/data/dummy_auth_source.dart`](lib/core/data/dummy_auth_source.dart) —
  Fuente en memoria, sólo con `ROBLE_CONTRACT_ID` vacío.
- [`lib/features/auth/auth_dependencies.dart`](lib/features/auth/auth_dependencies.dart) —
  Registro GetX.

### UI

- [`lib/features/auth/ui/viewmodels/authentication_controller.dart`](lib/features/auth/ui/viewmodels/authentication_controller.dart) —
  Estado de sesión, validación, y coordinación: suscripción a
  `sessionExpired`, garantía de la fila de perfil y refresco de proyectos.
- [`lib/features/auth/ui/pages/login_page.dart`](lib/features/auth/ui/pages/login_page.dart),
  [`register_page.dart`](lib/features/auth/ui/pages/register_page.dart),
  [`upgrade_account_page.dart`](lib/features/auth/ui/pages/upgrade_account_page.dart) —
  Pantallas de auth.
- [`lib/features/auth/ui/widgets/account_required_prompt.dart`](lib/features/auth/ui/widgets/account_required_prompt.dart) —
  Portón de invitado.

Flujo:

```text
SplashPage -> AuthenticationController.restoreSession()
           -> sessionExpired? -> /login con "Tu sesión caducó..."
LoginPage  -> login() / signInAsGuest() / quickDevLogin (DEV_LOGIN=true)
Register   -> signUp() -> register + login -> /home  (ya dentro)
```

## Profile feature

- [`lib/features/profile/data/datasources/roble_profile_data_source.dart`](lib/features/profile/data/datasources/roble_profile_data_source.dart) —
  Lee y escribe la tabla `profile`. Busca la fila propia por `_owner`.
- [`lib/features/profile/data/repositories/profile_repository.dart`](lib/features/profile/data/repositories/profile_repository.dart) —
  Traduce `RobleApi*` a `ProfileFailure` (403/404/red/tiempo).
- [`lib/features/profile/profile_dependencies.dart`](lib/features/profile/profile_dependencies.dart) —
  `registerProfileData()` (permanente, en `main`) y `registerProfile()`
  (controlador perezoso en `HomeBinding`).
- [`lib/features/profile/ui/pages/profile_page.dart`](lib/features/profile/ui/pages/profile_page.dart),
  [`edit_profile_page.dart`](lib/features/profile/ui/pages/edit_profile_page.dart) —
  Pantallas.

## Projects / Discover / Home

- `features/projects` — Proyectos (`project`), guardados, postulaciones y
  colaboraciones. `RobleProjectDataSource` usa `readPublicOrPrivate`.
- `features/discover` — Feed de descubrimiento.
- `features/home` — `SplashPage` (restaura sesión y enruta) y `HomePage`
  (IndexedStack de pestañas).

## Tests

- `test/features/auth/auth_repository_test.dart` — `signUp` encadena
  registro + entrada; delegación de `sessionExpired`.
- `test/features/auth/authentication_source_service_test.dart` — `DummyAuthSource`.
- `test/features/profile/roble_profile_data_source_test.dart` — Nunca devuelve
  el perfil de otra persona; `ensureMyProfile`/`updateMyProfile` crean sólo
  cuando hace falta.
- `test/features/projects/project_repository_test.dart`,
  `test/features/discover/discover_controller_test.dart` — Mapeo y errores.
- `test/widget_test.dart` — Plantilla original, no refleja la app.

## Límites actuales

- Sólo `data/datasources/*` habla con Roble; los repositorios sólo traducen
  excepciones y los viewmodels no tocan UI.
- No hay clases de caso de uso: los controladores llaman a los repositorios.
- `features/applications/project_applications.dart` sigue en memoria (falta
  conectar `project_join_request` del UML).
- `ILocalPreferences` está registrado pero ya no se usa: la sesión la
  persiste el paquete de Roble.
- El botón «Acceso rápido Dev» usa credenciales del servidor real y sólo
  aparece con `--dart-define=DEV_LOGIN=true` en debug.
