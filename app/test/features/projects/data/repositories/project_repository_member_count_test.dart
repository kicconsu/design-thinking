import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/data/dummy_data.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';
import 'package:imker/features/projects/data/repositories/project_repository.dart';
import 'package:imker/features/projects/domain/models/project.dart';

void main() {
  group('Project.memberCount', () {
    late InMemoryProjectDataSource source;
    late ProjectRepository repo;

    setUp(() {
      source = InMemoryProjectDataSource(DummyData());
      repo = ProjectRepository(source);
    });

    Future<Project> createProject() => repo.createProject(
      title: 'Proyecto nuevo',
      description: 'Descripción',
      jobs: const [],
      skills: const [],
    );

    /// Como en Roble, el creador figura como miembro con rol `owner`.
    Future<Project> createProjectWithOwnerRow() async {
      final project = await createProject();
      await source.addProjectMember(
        projectId: project.id,
        userId: 'creador',
        role: {'name': 'owner'},
      );
      return project;
    }

    test(
      'un proyecto sin filas de miembros cuenta a su creador: uno',
      () async {
        final project = await createProject();

        expect(project.memberCount, 1);
      },
    );

    test('cuenta una vez a cada miembro activo, creador incluido', () async {
      final project = await createProjectWithOwnerRow();
      await source.addProjectMember(projectId: project.id, userId: 'ana');
      await source.addProjectMember(projectId: project.id, userId: 'ana');
      await source.addProjectMember(projectId: project.id, userId: 'beto');

      final loaded = await repo.getProjectById(project.id);

      expect(loaded?.memberCount, 3); // creador + ana + beto
    });

    test('no mezcla los miembros de otros proyectos', () async {
      final a = await createProjectWithOwnerRow();
      final b = await createProjectWithOwnerRow();
      await source.addProjectMember(projectId: a.id, userId: 'ana');

      final all = await repo.getProjects();

      expect(all.firstWhere((p) => p.id == a.id).memberCount, 2);
      expect(all.firstWhere((p) => p.id == b.id).memberCount, 1);
    });

    test('quien salió deja de contar', () async {
      final project = await createProjectWithOwnerRow();
      await source.addProjectMember(projectId: project.id, userId: 'ana');
      await repo.leaveProject(projectId: project.id, userId: 'ana');

      final loaded = await repo.getProjectById(project.id);

      expect(loaded?.memberCount, 1);
    });
  });
}
