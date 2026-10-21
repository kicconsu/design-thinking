# Índice del código

`imker` es una app Flutter organizada por feature (arquitectura MVVM
pragmática). GetX aporta la inyección de dependencias, la navegación y el
estado reactivo. El backend es **Roble** (paquete `roble`): maneja tokens,
refresco de sesión y almacenamiento seguro; la app no arma peticiones HTTP.

## Capas

```text
Página / widget  ->  Controlador (viewmodel)  ->  Repositorio (interfaz en domain)
                                                    ->  Fuente de datos: Roble o memoria
```

- Solo `data/datasources/` habla con Roble. Los repositorios traducen sus
  excepciones a errores propios (`ProfileFailure`, `ProjectFailure`,
  `TrustFailure`) y los controladores no tocan la interfaz.
- Cada feature registra sus piezas en `<feature>_dependencies.dart`
  (`registerAuth()`, `registerProfileData()`, `registerProjects()`,
  `registerTasks()`, `registerTrust()`), que `lib/main.dart` llama al arrancar.
- Las fuentes en memoria (`InMemory*`) sirven a las pruebas y al modo sin
  contrato de Roble.

## Núcleo (`lib/core`, `lib/routes`)

| Archivo | Para qué sirve |
|---------|----------------|
| `core/roble/roble_config.dart` | Dirección del servidor y contrato, por `--dart-define` |
| `core/roble/roble_client.dart` | Un único cliente; id de la sesión y nombres de tabla |
| `core/utils/error_message.dart` | Excepciones de Roble a mensajes legibles |
| `core/utils/clock.dart` | Reloj inyectable (las reglas con fechas no usan `DateTime.now()`) |
| `core/utils/app_keys.dart` | `Key` de los controles que las pruebas necesitan |
| `core/widgets/` | Barra inferior, avatar, indicadores de confianza, editor de checklist |
| `routes/app_pages.dart` | Tabla de rutas y bindings |

## Features

| Feature | Qué hace | Piezas principales |
|---------|----------|--------------------|
| `auth` | Registro, inicio de sesión, invitado y sesión caducada | `AuthenticationController`, `AuthRepository`, `login_page`, `register_page` |
| `profile` | Perfil propio, edición, onboarding y ajustes | `ProfileController`, `ProfileRepository`, `ProfileView`, `profile_page` |
| `discover` | Feed de proyectos con filtros por carrera y habilidad y paginación | `DiscoverController`, `ProjectFilterIndex`, `discover_page`, `ProjectCard` |
| `projects` | Proyectos, solicitudes, invitaciones, miembros, salir y quitar, cerrar proyecto, fichas de personas | `ProjectRepository`, `CollaborationRequestsController`, `ProjectInfoPage`, `PersonProfilePage` |
| `tasks` | Tareas de un proyecto: reservar, checklist, comentarios, fecha límite | `TaskRepository`, `TaskBoardPage`, `TaskProgressPage`, `TaskDeadline` |
| `trust` | Indicadores de confianza de una persona | `TrustMetrics.calculate`, `TrustRepository` |
| `home` | Splash (restaura la sesión) y pestañas principales | `SplashPage`, `HomePage` |

### Reglas que conviene conocer

- **Salir y quitar miembros:** cierra la estancia en `project_member`
  (`left` o `removed`). El creador no puede salir ni ser quitado. Las tareas
  sin terminar de quien se va se liberan; las terminadas se conservan.
- **Cerrar proyecto:** solo el creador, sin reabrir. Un proyecto cerrado deja
  de recibir solicitudes e invitaciones, pero sigue visible.
- **Tareas:** al crear, cambiar de estado o borrar una tarea se recalcula el
  progreso del proyecto. Completar el checklist termina la tarea y desmarcarlo
  la reabre. Solo quien la reservó edita el checklist; la fecha límite la
  cambian quien creó la tarea y el creador del proyecto, mientras no esté
  terminada. El final del día elegido, en hora local, es el límite.
- **Contadores:** las tareas tomadas y terminadas por miembro se mantienen en
  `project_member` y alimentan la confianza. Si fallan, la tarea no se deshace.
- **Confianza:** cuatro indicadores de 0 a 100. *Cumplimiento* (de las tareas
  que tomó, cuántas terminó, promedio por proyecto), *entrega a tiempo*
  (terminadas con fecha límite antes de vencer), *proyectos completados* (los
  que están al 100 %) y un *compromiso* general que promedia los que tienen
  datos. Un indicador sin datos es «—», nunca 0 %.

## Datos

El modelo y las consultas guardadas de Roble están en [`../docs/db`](../docs/db).
Las consultas (`metricas_compromiso_por_proyecto`, `entregas_a_tiempo`,
`proyectos_filtrados`…) se piden por nombre; si falta alguna, la función que
depende de ella falla de forma visible, sin datos inventados.

## Pruebas

Ver [test/README.md](test/README.md) e
[integration_test/README.md](integration_test/README.md).

## Límites actuales

- No hay clases de caso de uso: los controladores llaman a los repositorios.
- `DummyAuthSource` (`lib/core/data/`) solo se usa cuando `ROBLE_CONTRACT_ID`
  está vacío.
- El botón «Acceso rápido Dev» usa credenciales reales y solo aparece con
  `--dart-define=DEV_LOGIN=true` en debug.
- El release se firma con la llave de debug; falta la firma definitiva.
