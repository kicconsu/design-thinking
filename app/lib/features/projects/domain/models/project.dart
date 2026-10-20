/// Entidad del dominio: un proyecto del feed de Imker.
class Project {
  const Project({
    required this.id,
    this.owner = '',
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.jobs,
    required this.skills,
    this.status = 'open',
    this.memberCount = 0,
    this.progress = 0,
  });

  final String id;
  final String owner;
  final String title;
  final String imageUrl;
  final String description;
  final List<String> jobs;
  final List<String> skills;
  final String status;
  /// Miembros activos del proyecto, el creador incluido.
  final int memberCount;

  /// Porcentaje (0–100) de tareas terminadas, calculado al cambiar una tarea.
  final double progress;

  bool get isOpen => status == 'open';

  Project copyWith({
    String? id,
    String? owner,
    String? title,
    String? imageUrl,
    String? description,
    List<String>? jobs,
    List<String>? skills,
    String? status,
    int? memberCount,
    double? progress,
  }) {
    return Project(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      jobs: jobs ?? this.jobs,
      skills: skills ?? this.skills,
      status: status ?? this.status,
      memberCount: memberCount ?? this.memberCount,
      progress: progress ?? this.progress,
    );
  }

  @override
  String toString() => 'Project(id: $id, title: $title, status: $status)';
}

