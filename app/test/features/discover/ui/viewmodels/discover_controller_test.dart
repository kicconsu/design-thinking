import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';
import 'package:imker/features/projects/domain/project_failure.dart';

import '../../../../support/fake_discover_repository.dart';
import '../../../../support/builders.dart';

List<String> ids(DiscoverController c) => c.projects.map((p) => p.id).toList();

void main() {
  late FakeDiscoverRepository repo;
  late DiscoverController controller;

  setUp(() {
    repo = FakeDiscoverRepository([
      aProject(id: 'a', title: 'a', jobs: ['Software'], skills: ['Dart']),
      aProject(
        id: 'b',
        title: 'b',
        jobs: ['Software'],
        skills: ['Python'],
        status: 'closed',
      ),
      aProject(id: 'c', title: 'c', jobs: ['Diseño'], skills: ['Figma']),
      aProject(
        id: 'd',
        title: 'd',
        jobs: ['Diseño', 'Software'],
        skills: ['Dart'],
      ),
    ]);
    controller = DiscoverController(repo, pageSize: 2);
  });

  group('carga', () {
    test('trae la primera página, el total y las opciones', () async {
      await controller.loadProjects();

      expect(ids(controller), ['a', 'b']);
      expect(controller.total.value, 4);
      expect(controller.hasMore, isTrue);
      expect(controller.careerOptions.map((o) => o.key), [
        'diseno',
        'software',
      ]);
      expect(controller.isLoading.value, isFalse);
      expect(controller.error.value, isNull);
    });

    test('un fallo sin proyectos queda como error de pantalla', () async {
      repo.failure = const ProjectFailure('Sin conexión');

      await controller.loadProjects();

      expect(controller.error.value, 'Sin conexión');
      expect(controller.projects, isEmpty);
      expect(controller.isLoading.value, isFalse);
    });

    test('un fallo al refrescar conserva la lista y avisa', () async {
      await controller.loadProjects();
      repo.failure = const ProjectFailure('Sin conexión');

      await controller.loadProjects();

      expect(ids(controller), ['a', 'b']);
      expect(controller.error.value, isNull);
      expect(controller.notice.value, 'Sin conexión');
    });
  });

  group('paginación', () {
    test('loadMore agrega la siguiente página hasta agotar', () async {
      await controller.loadProjects();

      await controller.loadMore();
      expect(ids(controller), ['a', 'b', 'c', 'd']);
      expect(controller.hasMore, isFalse);

      final asked = repo.pagesAsked.length;
      await controller.loadMore();
      expect(repo.pagesAsked.length, asked);
    });

    test('pide la página desde donde va y con el filtro actual', () async {
      await controller.setCareer('software');
      await controller.loadMore();

      final last = repo.pagesAsked.last;
      expect(last.offset, 2);
      expect(last.limit, 2);
      expect(last.filter.career, 'software');
    });

    test('no duplica proyectos si la lista se movió en el servidor', () async {
      await controller.loadProjects();
      repo.projects = [aProject(id: 'z', title: 'z'), ...repo.projects];

      await controller.loadMore();

      expect(ids(controller).toSet().length, ids(controller).length);
    });

    test('dos loadMore seguidos piden una sola página', () async {
      await controller.loadProjects();
      final before = repo.pagesAsked.length;

      await Future.wait([controller.loadMore(), controller.loadMore()]);

      expect(repo.pagesAsked.length, before + 1);
    });

    test('un fallo de página avisa y deja pedir de nuevo', () async {
      await controller.loadProjects();
      repo.failure = const ProjectFailure('Sin conexión');

      await controller.loadMore();
      expect(ids(controller), ['a', 'b']);
      expect(controller.notice.value, 'Sin conexión');
      expect(controller.isLoadingMore.value, isFalse);

      repo.failure = null;
      await controller.loadMore();
      expect(ids(controller), ['a', 'b', 'c', 'd']);
    });
  });

  group('filtros', () {
    test(
      'cambiar la carrera recarga, vuelve al inicio y cuenta el reset',
      () async {
        await controller.loadProjects();
        final resets = controller.resetCount.value;

        await controller.setCareer('diseno');

        expect(ids(controller), ['c', 'd']);
        expect(controller.total.value, 2);
        expect(controller.filter.value.career, 'diseno');
        expect(controller.resetCount.value, resets + 1);
      },
    );

    test('las habilidades ofrecidas siguen a la carrera', () async {
      await controller.setCareer('diseno');

      expect(controller.skillOptions.map((o) => o.key), ['dart', 'figma']);
    });

    test(
      'cambiar la carrera descarta la habilidad que ya no se ofrece',
      () async {
        await controller.setCareer('software');
        await controller.setSkill('python');
        expect(controller.filter.value.skill, 'python');

        await controller.setCareer('diseno');

        expect(controller.filter.value, const ProjectFilter(career: 'diseno'));
        expect(controller.notice.value, isNotNull);
      },
    );

    test('solo abiertos y limpiar filtros', () async {
      await controller.setOnlyOpen(true);
      expect(ids(controller), ['a', 'c']);

      await controller.clearFilters();
      expect(controller.filter.value, ProjectFilter.none);
      expect(controller.total.value, 4);
    });

    test('refrescar conserva el filtro y no reinicia la posición', () async {
      await controller.setCareer('diseno');
      final resets = controller.resetCount.value;

      await controller.loadProjects();

      expect(controller.filter.value.career, 'diseno');
      expect(controller.resetCount.value, resets);
      expect(controller.notice.value, isNull);
    });

    test(
      'si la opción elegida desaparece al recargar, se limpia con aviso',
      () async {
        await controller.setCareer('diseno');
        repo.projects = repo.projects
            .where((p) => !p.jobs.contains('Diseño'))
            .toList();

        await controller.loadProjects();

        expect(controller.filter.value, ProjectFilter.none);
        expect(controller.notice.value, isNotNull);
        expect(controller.total.value, 2);
      },
    );

    test('si falla aplicar un filtro, se queda el anterior', () async {
      await controller.loadProjects();
      repo.failure = const ProjectFailure('Sin conexión');

      await controller.setCareer('diseno');

      expect(controller.filter.value, ProjectFilter.none);
      expect(ids(controller), ['a', 'b']);
      expect(controller.notice.value, 'Sin conexión');
    });
  });

  group('sesión', () {
    test('clear vacía todo y descarta lo que venía en vuelo', () async {
      await controller.setCareer('diseno');
      repo.gate = Completer<void>();

      final pending = controller.loadProjects();
      controller.clear();
      repo.gate!.complete();
      await pending;

      expect(controller.projects, isEmpty);
      expect(controller.filter.value, ProjectFilter.none);
      expect(controller.total.value, 0);
      expect(controller.isLoading.value, isFalse);
      expect(controller.error.value, isNull);
    });

    test('una respuesta lenta no pisa a la más nueva', () async {
      final slow = Completer<void>();
      repo.gate = slow;
      final first = controller.setCareer('software');

      repo.gate = null;
      await controller.setCareer('diseno');
      slow.complete();
      await first;

      expect(controller.filter.value.career, 'diseno');
      expect(ids(controller), ['c', 'd']);
    });
  });
}
