/// Ítem del checklist de una tarea (columna `task.checklist`).
class Subtask {
  const Subtask({required this.title, this.done = false});

  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  /// Una entrada mal formada no debe tumbar la tarea: devuelve null y quien
  /// lee la descarta.
  static Subtask? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = raw['title']?.toString().trim() ?? '';
    if (title.isEmpty) return null;
    return Subtask(title: title, done: raw['done'] == true);
  }

  @override
  bool operator ==(Object other) =>
      other is Subtask && other.title == title && other.done == done;

  @override
  int get hashCode => Object.hash(title, done);
}
