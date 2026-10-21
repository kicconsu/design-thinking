// Punto de entrada de las pruebas de integración: corre los seis flujos.
//
// Cada flujo vive en su propio archivo, en la misma ruta que el código que
// recorre dentro de `lib/features/`. Para correr uno solo, apunta
// `--target` a ese archivo.
//
// Ninguna prueba habla con Roble: los datos salen de los dobles de
// `integration_test/support`.

import 'package:integration_test/integration_test.dart';

import 'features/discover/discover_apply_flow_test.dart' as discover_apply;
import 'features/projects/accept_request_flow_test.dart' as accept_request;
import 'features/projects/reject_request_flow_test.dart' as reject_request;
import 'features/tasks/create_task_flow_test.dart' as create_task;
import 'features/tasks/finish_task_flow_test.dart' as finish_task;
import 'features/tasks/reserve_task_flow_test.dart' as reserve_task;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  discover_apply.main(); // 1. descubrir y aplicar a un proyecto
  accept_request.main(); // 2. ver solicitud y aceptar
  reject_request.main(); // 3. ver solicitud y rechazar
  create_task.main(); // 4. crear tarea con subtareas
  reserve_task.main(); // 5. asignarse tarea y avanzar parcialmente
  finish_task.main(); // 6. terminar tarea asignada
}
