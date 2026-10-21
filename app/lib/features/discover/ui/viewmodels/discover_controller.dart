import 'package:get/get.dart';

import 'package:imker/features/discover/domain/models/filter_option.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/domain/models/project_page.dart';
import 'package:imker/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/domain/project_failure.dart';

/// Feed de Descubrir: filtros, opciones de los selectores y paginación.
///
/// Los filtros viven mientras dure la sesión (se vacían con [clear]) y no se
/// guardan entre ejecuciones. Cada recarga o cambio de filtro invalida las
/// respuestas que quedaron en vuelo, para que una lenta no pise a una nueva.
class DiscoverController extends GetxController {
  DiscoverController(this._repository, {this.pageSize = 20});

  final IDiscoverRepository _repository;
  final int pageSize;

  final RxList<Project> projects = <Project>[].obs;
  final Rx<ProjectFilter> filter = ProjectFilter.none.obs;
  final RxList<FilterOption> careerOptions = <FilterOption>[].obs;
  final RxList<FilterOption> skillOptions = <FilterOption>[].obs;

  /// Proyectos que cumplen el filtro, sin paginar.
  final RxInt total = 0.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  /// Error de la carga inicial; solo bloquea la pantalla si no hay proyectos.
  final RxnString error = RxnString();

  /// Aviso que no bloquea: una recarga o página que falló, o un filtro que se
  /// descartó porque ya no existe. La vista lo muestra y llama [clearNotice].
  final RxnString notice = RxnString();

  /// Sube cada vez que el feed debe volver a la primera tarjeta (F-09).
  final RxInt resetCount = 0.obs;

  int _generation = 0;

  bool get hasMore => projects.length < total.value;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  /// Carga desde cero conservando el filtro; si una opción elegida ya no
  /// existe, la descarta con un aviso. También sirve para refrescar.
  Future<void> loadProjects() => _load(filter.value);

  /// Aplica un filtro completo (el de la hoja de filtros).
  Future<void> applyFilter(ProjectFilter wanted) => _load(wanted);

  /// Opciones y cantidad de resultados que daría [candidate], sin aplicarlo.
  /// Alimentan la hoja de filtros; un fallo lanza [ProjectFailure].
  Future<FilterOptions> previewOptions(ProjectFilter candidate) =>
      _repository.getOptions(candidate);

  Future<int> previewCount(ProjectFilter candidate) async =>
      (await _repository.getPage(filter: candidate, offset: 0, limit: 1)).total;

  Future<void> setCareer(String? key) => _load(filter.value.withCareer(key));

  Future<void> setSkill(String? key) => _load(filter.value.withSkill(key));

  Future<void> setOnlyOpen(bool value) =>
      _load(filter.value.withOnlyOpen(value));

  Future<void> clearFilters() => _load(ProjectFilter.none);

  /// Pide la página siguiente. No hace nada si ya se está cargando o no hay más.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    final generation = _generation;
    isLoadingMore.value = true;
    try {
      final page = await _repository.getPage(
        filter: filter.value,
        offset: projects.length,
        limit: pageSize,
      );
      if (generation != _generation) return;
      final known = projects.map((p) => p.id).toSet();
      projects.addAll(page.projects.where((p) => !known.contains(p.id)));
      total.value = page.total;
    } catch (e) {
      if (generation != _generation) return;
      notice.value = _message(e);
    } finally {
      if (generation == _generation) isLoadingMore.value = false;
    }
  }

  void clearNotice() => notice.value = null;

  /// Vuelve al estado de antes de iniciar sesión: sin filtros ni proyectos.
  void clear() {
    _generation++;
    projects.clear();
    careerOptions.clear();
    skillOptions.clear();
    filter.value = ProjectFilter.none;
    total.value = 0;
    isLoading.value = false;
    isLoadingMore.value = false;
    error.value = null;
    notice.value = null;
  }

  Future<void> _load(ProjectFilter wanted) async {
    final generation = ++_generation;
    final previous = filter.value;
    isLoading.value = true;
    isLoadingMore.value = false;
    error.value = null;
    try {
      var applied = wanted;
      var options = await _repository.getOptions(applied);
      if (generation != _generation) return;

      // Una carrera o habilidad que ya no se ofrece se descarta. Si cae la
      // carrera, las habilidades ofrecidas cambian y hay que pedirlas de nuevo.
      var dropped = false;
      if (applied.career != null &&
          !options.careers.any((o) => o.key == applied.career)) {
        applied = applied.withCareer(null);
        dropped = true;
        options = await _repository.getOptions(applied);
        if (generation != _generation) return;
      }
      if (applied.skill != null &&
          !options.skills.any((o) => o.key == applied.skill)) {
        applied = applied.withSkill(null);
        dropped = true;
      }

      final page = await _repository.getPage(
        filter: applied,
        offset: 0,
        limit: pageSize,
      );
      if (generation != _generation) return;

      filter.value = applied;
      careerOptions.assignAll(options.careers);
      skillOptions.assignAll(options.skills);
      projects.assignAll(page.projects);
      total.value = page.total;
      if (applied != previous) resetCount.value++;
      if (dropped) {
        notice.value = 'Un filtro ya no está disponible y se quitó.';
      }
    } catch (e) {
      if (generation != _generation) return;
      if (projects.isEmpty) {
        error.value = _message(e);
      } else {
        notice.value = _message(e);
      }
    } finally {
      if (generation == _generation) isLoading.value = false;
    }
  }

  String _message(Object e) => e is ProjectFailure
      ? e.message
      : 'Ocurrió un error inesperado al cargar los proyectos.';
}
