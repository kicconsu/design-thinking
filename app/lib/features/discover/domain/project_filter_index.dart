import 'package:imker/core/utils/normalize_label.dart';
import 'package:imker/features/discover/domain/models/filter_option.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/projects/domain/models/project.dart';

/// Filtrado y opciones de Descubrir sobre una lista de proyectos en memoria.
///
/// Es la implementación de la fuente en memoria (modo mock) y la referencia de
/// lo que hacen las consultas guardadas `proyectos_filtrados` y
/// `opciones_filtros_proyectos`. Las claves se calculan una sola vez al construir.
class ProjectFilterIndex {
  ProjectFilterIndex(Iterable<Project> projects)
    : _entries = [for (final p in projects) _Entry(p)];

  final List<_Entry> _entries;

  /// Proyectos que cumplen el filtro, en el orden recibido.
  List<Project> apply(ProjectFilter filter) => [
    for (final e in _entries)
      if (_matches(e, filter)) e.project,
  ];

  /// Carreras ofrecidas: todas las de los proyectos (solo abiertos si se pide),
  /// sin recortar por la carrera ni por la habilidad elegidas.
  List<FilterOption> careerOptions(ProjectFilter filter) =>
      _options(_candidates(filter), (e) => e.careers);

  /// Habilidades ofrecidas: las de los proyectos que listan la carrera elegida.
  List<FilterOption> skillOptions(ProjectFilter filter) {
    final career = filter.career;
    final candidates = _candidates(filter)
        .where((e) => career == null || e.careers.containsKey(career));
    return _options(candidates, (e) => e.skills);
  }

  /// Descarta carrera o habilidad que ya no se ofrecen (tras recargar el feed o
  /// cambiar la carrera).
  FilterReconciliation reconcile(ProjectFilter filter) {
    var result = filter;
    var droppedCareer = false;
    var droppedSkill = false;

    if (result.career != null &&
        !careerOptions(result).any((o) => o.key == result.career)) {
      result = result.withCareer(null);
      droppedCareer = true;
    }
    if (result.skill != null &&
        !skillOptions(result).any((o) => o.key == result.skill)) {
      result = result.withSkill(null);
      droppedSkill = true;
    }
    return FilterReconciliation(
      filter: result,
      droppedCareer: droppedCareer,
      droppedSkill: droppedSkill,
    );
  }

  Iterable<_Entry> _candidates(ProjectFilter filter) =>
      filter.onlyOpen ? _entries.where((e) => e.project.isOpen) : _entries;

  bool _matches(_Entry e, ProjectFilter filter) {
    if (filter.onlyOpen && !e.project.isOpen) return false;
    final career = filter.career;
    if (career != null && !e.careers.containsKey(career)) return false;
    final skill = filter.skill;
    if (skill != null && !e.skills.containsKey(skill)) return false;
    return true;
  }

  List<FilterOption> _options(
    Iterable<_Entry> entries,
    Map<String, Set<String>> Function(_Entry) labelsOf,
  ) {
    final counts = <String, int>{};
    final variants = <String, Map<String, int>>{};
    for (final e in entries) {
      labelsOf(e).forEach((key, labels) {
        counts[key] = (counts[key] ?? 0) + 1;
        final byLabel = variants.putIfAbsent(key, () => {});
        for (final label in labels) {
          byLabel[label] = (byLabel[label] ?? 0) + 1;
        }
      });
    }
    final keys = counts.keys.toList()..sort();
    return [
      for (final key in keys)
        FilterOption(
          key: key,
          label: _mostFrequent(variants[key]!),
          count: counts[key]!,
        ),
    ];
  }

  String _mostFrequent(Map<String, int> byLabel) {
    String? best;
    var bestCount = 0;
    byLabel.forEach((label, count) {
      if (count > bestCount ||
          (count == bestCount && label.compareTo(best!) < 0)) {
        best = label;
        bestCount = count;
      }
    });
    return best!;
  }
}

class _Entry {
  _Entry(this.project)
    : careers = _byKey(project.jobs),
      skills = _byKey(project.skills);

  final Project project;

  /// Clave normalizada → variantes escritas en este proyecto.
  final Map<String, Set<String>> careers;
  final Map<String, Set<String>> skills;

  static Map<String, Set<String>> _byKey(List<String> labels) {
    final result = <String, Set<String>>{};
    for (final label in labels) {
      final key = normalizeLabel(label);
      if (key.isEmpty) continue;
      result.putIfAbsent(key, () => {}).add(label);
    }
    return result;
  }
}
