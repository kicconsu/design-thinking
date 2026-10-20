/// Una opción de un selector de filtro.
class FilterOption {
  const FilterOption({
    required this.key,
    required this.label,
    required this.count,
  });

  /// Forma normalizada, con la que se compara (`normalizeLabel`).
  final String key;

  /// Variante más frecuente entre los proyectos; en empate, la primera por orden alfabético.
  final String label;

  /// Proyectos distintos que la tienen.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is FilterOption &&
      other.key == key &&
      other.label == label &&
      other.count == count;

  @override
  int get hashCode => Object.hash(key, label, count);

  @override
  String toString() => 'FilterOption($key, "$label", $count)';
}
