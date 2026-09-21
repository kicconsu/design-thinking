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
    this.members = const [],
    this.applicantsCount = 0,
  });

  final String id;
  final String owner;
  final String title;
  final String imageUrl;
  final String description;
  final List<String> jobs;
  final List<String> skills;
  final String status;
  final List<String> members;
  final int applicantsCount;

  bool get isOpen => status == 'open';

  @override
  String toString() => 'Project(id: $id, title: $title, status: $status)';
}
