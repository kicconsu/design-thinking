import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/checklist_editor.dart';

import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';
import 'project_info_controller.dart';
import 'user_projects_controller.dart';

/// Estado de la pestaña "Info. básica": los borradores de lo que se edita y
/// el guardado. Los borradores viven aquí (y no en el widget) para que
/// cambiar de pestaña no los pierda. Una instancia por proyecto abierto.
class ProjectBasicInfoController extends GetxController {
  /// [isOwner] sustituye a la comprobación real de dueño: solo para
  /// pruebas.
  ProjectBasicInfoController(this._info, {bool Function()? isOwner})
    : _canEditOverride = isOwner,
      title = TextEditingController(text: _info.project.value.title),
      description = TextEditingController(
        text: _info.project.value.description,
      ),
      jobs = [for (final j in _info.project.value.jobs) ChecklistEntry(j)],
      skills = [for (final s in _info.project.value.skills) ChecklistEntry(s)];

  final ProjectInfoController _info;
  final bool Function()? _canEditOverride;

  final TextEditingController title;
  final TextEditingController description;

  /// Carreras relacionadas (`project.jobs`) y conocimientos requeridos
  /// (`project.skills`). Las casillas desmarcadas se descartan al guardar.
  List<ChecklistEntry> jobs;
  List<ChecklistEntry> skills;

  final RxBool isSaving = false.obs;

  /// Solo el creador edita la información del proyecto; el resto la lee.
  bool get canEdit {
    final override = _canEditOverride;
    if (override != null) return override();
    return Get.isRegistered<UserProjectsController>() &&
        Get.find<UserProjectsController>().isOwner(_info.project.value);
  }

  @override
  void onClose() {
    title.dispose();
    description.dispose();
    super.onClose();
  }

  /// Guarda el borrador. Devuelve null si salió bien o el mensaje de error.
  Future<String?> save() async {
    if (!canEdit) {
      return 'Solo el creador del proyecto puede editar esta información.';
    }
    if (isSaving.value) return null;
    isSaving.value = true;
    try {
      final updated = await Get.find<IProjectRepository>().updateProject(
        id: _info.project.value.id,
        title: title.text,
        description: description.text,
        jobs: [
          for (final e in jobs)
            if (e.checked) e.label,
        ],
        skills: [
          for (final e in skills)
            if (e.checked) e.label,
        ],
      );
      _info.applyProject(updated);
      // Lo que quedó guardado (sin espacios de más) es lo que se ve.
      title.text = updated.title;
      description.text = updated.description;
      return null;
    } on ProjectFailure catch (e) {
      return e.message;
    } finally {
      isSaving.value = false;
    }
  }
}
