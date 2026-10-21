import 'package:imker/features/projects/domain/models/project.dart';

/// Un proyecto de ejemplo. Solo se nombra lo que la prueba necesita; el resto
/// queda en valores neutros.
///
/// Sin [title], el título es «Proyecto» más el id.
Project aProject({
  String id = 'p1',
  String? title,
  String owner = '',
  String status = 'open',
  String description = '',
  List<String> jobs = const [],
  List<String> skills = const [],
  int memberCount = 0,
  double progress = 0,
}) => Project(
  id: id,
  owner: owner,
  title: title ?? 'Proyecto $id',
  imageUrl: '',
  description: description,
  jobs: jobs,
  skills: skills,
  status: status,
  memberCount: memberCount,
  progress: progress,
);
