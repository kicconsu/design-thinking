import 'package:get/get.dart';

import 'package:imker/features/tasks/domain/repositories/i_task_repository.dart';

import '../../domain/project_failure.dart';

/// Libera las tareas sin terminar de [userId] en [projectId] cuando deja el
/// proyecto (sale o lo sacan). Las terminadas se conservan a su nombre.
///
/// Es limpieza, no la operación principal: si falla, la persona ya salió y las
/// tareas siguen reservadas hasta que alguien las libere. Devuelve cuántas
/// liberó (0 si falló o no había).
Future<int> releaseTasksOf(String projectId, String userId) async {
  if (!Get.isRegistered<ITaskRepository>()) return 0;
  try {
    return await Get.find<ITaskRepository>().releaseUnfinishedTasks(
      projectId: projectId,
      userId: userId,
    );
  } on ProjectFailure {
    return 0;
  }
}
