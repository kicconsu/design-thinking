//Placeholder fields

class Project {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> jobs;
  final List<String> skills;
  final String description;
  final List<String> members;
  final String status;
  final int applicantsCount;

  const Project({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.jobs,
    required this.skills,
    required this.description,
    this.members = const [],
    this.status = 'En Desarrollo',
    this.applicantsCount = 0,
  });
}
