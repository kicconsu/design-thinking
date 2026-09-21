import 'package:get/get.dart';

import '../../domain/models/project.dart';
import '../../domain/project_failure.dart';
import '../../domain/repositories/i_project_repository.dart';

class DiscoverController extends GetxController {
  DiscoverController(this._repository);

  final IProjectRepository _repository;

  final RxList<Project> projects = <Project>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      isLoading.value = true;
      error.value = null;
      final result = await _repository.getProjects();
      projects.assignAll(result);
    } on ProjectFailure catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'Ocurrió un error inesperado al cargar los proyectos.';
    } finally {
      isLoading.value = false;
    }
  }
}
