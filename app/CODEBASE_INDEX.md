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
  Lee y escribe la tabla `profile`. Pide la fila propia con filtro `_owner`;
  `career` se guarda como `{program, institution}`.
- [`lib/features/profile/data/repositories/profile_repository.dart`](lib/features/profile/data/repositories/profile_repository.dart) —
  Traduce `RobleApi*` a `ProfileFailure` (403/404/red/tiempo).
- [`lib/features/profile/profile_dependencies.dart`](lib/features/profile/profile_dependencies.dart) —
  `registerProfileData()` (en `main`): datasource, repositorio y la única
  instancia permanente de `ProfileController`. Auth lo carga al entrar y lo
  vacía (`clear()`) al salir.
- [`lib/features/profile/ui/widgets/profile_form_fields.dart`](lib/features/profile/ui/widgets/profile_form_fields.dart) —
  Formulario compartido (carrera, institución, resumen, habilidades).
- [`lib/features/profile/ui/widgets/profile_view.dart`](lib/features/profile/ui/widgets/profile_view.dart) —
  Presentación de un perfil (cabecera, sobre mí, habilidades, proyectos,
  indicadores, historial). Sin GetX: sirve para el perfil propio y, a futuro,
  para el de otra persona. `core/widgets/profile_avatar.dart` pone iniciales
  (o la foto cuando haya `imageUrl`).
- [`lib/features/profile/ui/pages/onboarding_page.dart`](lib/features/profile/ui/pages/onboarding_page.dart) —
  Primeros datos del perfil (omitible), ruta `/onboarding`. Se abre tras
  `signUp` y tras `upgradeAccount`; los termina en Home (en Perfil si venía de
  invitado). La tarjeta «Completa tu perfil» de `ProfileView` cubre a quien
  lo omitió y a las cuentas anteriores.
- [`lib/features/profile/ui/pages/profile_page.dart`](lib/features/profile/ui/pages/profile_page.dart),
  [`edit_profile_page.dart`](lib/features/profile/ui/pages/edit_profile_page.dart),
  [`settings_page.dart`](lib/features/profile/ui/pages/settings_page.dart)
  (ajustes y cerrar sesión), `profile_projects_page.dart`,
  `trust_indicators_page.dart`, `collaboration_history_page.dart` —
  Pantallas.

## Projects / Discover / Home

- `features/projects` — Proyectos (`project`), guardados, postulaciones y
  colaboraciones. `RobleProjectDataSource` usa `readPublicOrPrivate`.
- `features/projects` también tiene la vista de información de un proyecto
  (`ProjectInfoPage`: pestañas Progreso, Info. básica y Miembros). Los miembros
  salen de `project_member` (solo `status` activo) y su nombre y carrera de
  `profile` (`IProjectRepository.getProjectMembers`); un perfil ilegible no
  tumba la lista. `core/roble/session_user.dart` da el `user_id` de la sesión.
- `features/tasks` — Tareas (`task`) y progreso. `TaskRepository` recalcula
  `project.progress` (tareas `done` / total) tras crear, cambiar de estado o
  borrar una tarea, y reserva tareas (`assignee_id`) sin pisar a quien se
  adelantó. `TaskBoardPage` es el gabinete y `TaskProgressPage` el progreso
  de una tarea: descripción y checklist (`task.checklist`, jsonb; lo edita
  solo quien la reservó; completarlo termina la tarea y desmarcarlo la
  reabre) y comentarios (`contribution`, planos: sin respuestas ni votos).
  `core/widgets/checklist_editor.dart` es el editor de checklist compartido.
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
- `test/features/profile/profile_repository_test.dart` — Mapeo de `skills`
  (array en la raíz), `career`, `isComplete` y traducción de errores.
- `test/features/profile/profile_controller_test.dart` — Carga, guardado,
  `clear()` y descarte de cargas de una sesión anterior.
- `test/features/profile/profile_form_test.dart` — Formulario compartido.
- `test/features/profile/profile_view_test.dart` — `ProfileView`, avatar y ajustes.
- `test/features/profile/onboarding_page_test.dart` — Guardar, omitir, error y destino en Home.
- `test/features/projects/project_repository_test.dart`,
  `test/features/discover/discover_controller_test.dart` — Mapeo y errores.
- `test/core/string_list_test.dart` — Lectura de columnas jsonb con array
  en la raíz (`decodeStringList`).
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
