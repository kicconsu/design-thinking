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
  `registerProjects()`, `registerTasks()`, `registerTrust()` y arranca `MyApp`.
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

## Salir y quitar miembros

- `ProjectRepository.leaveProject` / `removeMember` cierran la estancia en
  `project_member` (`left` / `removed` + `leftAt`) con
  `IProjectDataSource.endMembership`. El creador no puede salir ni ser
  quitado. Salir también borra el `project_saved` propio. Son repetibles.
- `ITaskRepository.releaseUnfinishedTasks` libera las tareas `todo`/`doing` de
  quien se va; las terminadas se conservan a su nombre. No cambia el progreso
  ni `tasks_taken`: lo soltado sigue contando como tomado.
- Salir: menú ⋮ en la tarjeta del título de `ProjectInfoPage` (el creador no lo
  ve). Quitar: botón en `MemberProfilePage` (ficha del miembro, se abre desde
  la pestaña Miembros), solo para el creador sobre colaboradores.
- Cerrar proyecto: el creador lo cierra desde ese mismo menú ⋮
  (`IProjectRepository.closeProject` → `status = closed`, sin reabrir desde la
  app). Un proyecto cerrado ya no recibe solicitudes ni invitaciones:
  `createJoinRequest`, `acceptJoinRequest` y `acceptInvitation` lanzan
  `ProjectFailure`; rechazar o declinar lo pendiente sigue permitido. Sigue en
  el feed y quienes ya colaboran siguen dentro. La ficha de postulación muestra
  `ClosedProjectBanner` en vez de postular, «Aplicar» pasa a «Cerrado» y las
  invitaciones a proyectos cerrados no se listan. En el historial de
  colaboración del perfil, los cerrados (creados o no) pasan a «Proyectos
  anteriores» y salen de «Colaborando ahora» y «Proyectos creados».

## Perfil de otras personas

- `PersonProfilePage` (`projects/ui/pages`): perfil de solo lectura de una
  persona más en qué anda (`IProjectRepository.getProjectsOfPerson`: creados y
  activos). Si se abre desde un proyecto del que es miembro, añade «En este
  proyecto» y el creador puede quitarla. `openPersonProfile` es la entrada
  común: a un invitado le pide cuenta.
- `ApplicantDetailPage` (solicitudes) es esa misma ficha con la solicitud
  encima (`header`) y aceptar/rechazar al pie (`bottomBar`). Es la única que
  pasa `showTrust`: carga además sus indicadores de confianza
  (`ITrustRepository.getTrustMetricsOf`; si no se pueden calcular se ve el
  texto de «sin historial») y ofrece el historial, que es
  `CollaborationHistoryPage(onlyPrevious: true)` con
  `IProjectRepository.getProjectsParticipatedBy` (proyectos con estancia en
  cualquier estado, menos el de la solicitud). «Anterior» es lo que la página ya
  define: un proyecto cerrado. Para incluir también los abiertos basta con no
  pasar `onlyPrevious`. Las invitaciones
  dicen «Te invitó X ›» (`InviterRow`); los nombres salen de `PeopleDirectory`,
  caché de sesión con una lectura por persona.
- Se abre desde la pestaña Miembros y desde «Integrantes» del detalle de un
  proyecto (lista real, ya no textos).

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
  adelantó. También mantiene los contadores que alimentan las métricas de
  confianza: `project.total_tasks` (se recalcula con el progreso) y, en
  `project_member`, `tasks_taken` (incremental: +1 al reservar, -1 al borrar la
  tarea) y `tasks_finished` (se recalcula desde `task` al terminar o reabrir;
  con varias estancias, cada fila anota solo lo nuevo: regla en
  `domain/models/member_stay.dart`). Los contadores son derivados: si fallan
  la tarea no se deshace. `TaskBoardPage` es el gabinete y `TaskProgressPage` el progreso
  de una tarea: descripción y checklist (`task.checklist`, jsonb; lo edita
  solo quien la reservó; completarlo termina la tarea y desmarcarlo la
  reabre) y comentarios (`contribution`, planos: sin respuestas ni votos).
  `core/widgets/checklist_editor.dart` es el editor de checklist compartido.
- `features/trust` — Indicadores de confianza de una persona (compromiso,
  entrega a tiempo, tasa de respuesta, proyectos completados), de 0 a 100.
  `TrustMetrics.calculate` es la regla pura: cada proyecto en el que participó
  pesa igual; compromiso = promedio de `tasks_finished / total_tasks` por
  proyecto, tasa de respuesta = promedio de `tasks_finished / tasks_taken`,
  completados = proyectos con `progress = 100` entre todos, entrega a tiempo =
  `finished_at <= deadline` entre las terminadas con `deadline`. Un proyecto sin
  denominador no entra en el promedio. Lee con las consultas guardadas
  `metricas_compromiso_por_proyecto` y `entregas_a_tiempo` (ver
  `docs/db/saved_queries.sql`), que se piden por lotes de ids; dependen de los
  contadores que mantiene `features/tasks`. `getCommitmentScores` alimenta, con
  una sola consulta por proyecto, el «Compromiso N %» de la lista de solicitudes
  (`CollaborationRequestsController`).
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
