import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/discover/domain/models/filter_option.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/domain/project_filter_index.dart';
import 'package:imker/features/projects/domain/models/project.dart';

import '../../../support/builders.dart';

List<String> ids(List<Project> projects) => projects.map((p) => p.id).toList();

void main() {
  final software = aProject(
    id: 'a',
    title: 'a',
    jobs: ['Ing. Software', 'Diseño'],
    skills: ['Dart', 'Flutter'],
  );
  final softwareClosed = aProject(
    id: 'b',
    title: 'b',
    jobs: ['ing software'],
    skills: ['Python'],
    status: 'closed',
  );
  final design = aProject(
    id: 'c',
    title: 'c',
    jobs: ['Diseño'],
    skills: ['Figma', 'dart'],
  );
  final noTags = aProject(id: 'd', title: 'd');
  final all = [software, softwareClosed, design, noTags];
  final index = ProjectFilterIndex(all);

  group('apply', () {
    test('sin filtros devuelve todo en el mismo orden', () {
      expect(ids(index.apply(ProjectFilter.none)), ['a', 'b', 'c', 'd']);
    });

    test('filtra por carrera comparando normalizado', () {
      const filter = ProjectFilter(career: 'ing software');
      expect(ids(index.apply(filter)), ['a', 'b']);
    });

    test('filtra por habilidad sin distinguir mayúsculas', () {
      const filter = ProjectFilter(skill: 'dart');
      expect(ids(index.apply(filter)), ['a', 'c']);
    });

    test('carrera y habilidad se combinan con Y', () {
      const filter = ProjectFilter(career: 'diseno', skill: 'dart');
      expect(ids(index.apply(filter)), ['a', 'c']);
      const none = ProjectFilter(career: 'ing software', skill: 'figma');
      expect(index.apply(none), isEmpty);
    });

    test('solo abiertos oculta los cerrados', () {
      const filter = ProjectFilter(onlyOpen: true);
      expect(ids(index.apply(filter)), ['a', 'c', 'd']);
    });

    test(
      'un proyecto sin etiquetas solo sale con carrera y habilidad en Todas',
      () {
        expect(ids(index.apply(ProjectFilter.none)), contains('d'));
        expect(
          ids(index.apply(const ProjectFilter(career: 'diseno'))),
          isNot(contains('d')),
        );
        expect(
          ids(index.apply(const ProjectFilter(skill: 'dart'))),
          isNot(contains('d')),
        );
      },
    );
  });

  group('opciones', () {
    test('carreras: sin repetidos, orden por clave, conteo por proyecto', () {
      expect(index.careerOptions(ProjectFilter.none), const [
        FilterOption(key: 'diseno', label: 'Diseño', count: 2),
        FilterOption(key: 'ing software', label: 'Ing. Software', count: 2),
      ]);
    });

    test(
      'la etiqueta es la variante más frecuente; en empate, la alfabética',
      () {
        final idx = ProjectFilterIndex([
          aProject(id: '1', title: '1', jobs: ['Ing. Software']),
          aProject(id: '2', title: '2', jobs: ['ing software']),
          aProject(id: '3', title: '3', jobs: ['ing software']),
        ]);
        expect(
          idx.careerOptions(ProjectFilter.none).single.label,
          'ing software',
        );

        final tie = ProjectFilterIndex([
          aProject(id: '1', title: '1', jobs: ['Ing. Software']),
          aProject(id: '2', title: '2', jobs: ['ing software']),
        ]);
        expect(
          tie.careerOptions(ProjectFilter.none).single.label,
          'Ing. Software',
        );
      },
    );

    test('una variante repetida dentro de un proyecto cuenta una vez', () {
      final idx = ProjectFilterIndex([
        aProject(id: '1', title: '1', jobs: ['Diseño', 'diseno', 'DISEÑO']),
      ]);
      expect(idx.careerOptions(ProjectFilter.none).single.count, 1);
    });

    test('las habilidades dependen de la carrera elegida', () {
      const filter = ProjectFilter(career: 'ing software');
      final keys = index.skillOptions(filter).map((o) => o.key);
      expect(keys, ['dart', 'flutter', 'python']);
    });

    test('sin carrera, todas las habilidades', () {
      final keys = index.skillOptions(ProjectFilter.none).map((o) => o.key);
      expect(keys, ['dart', 'figma', 'flutter', 'python']);
      expect(index.skillOptions(ProjectFilter.none).first.count, 2);
    });

    test('las carreras no se recortan por la habilidad elegida', () {
      const filter = ProjectFilter(skill: 'figma');
      expect(
        index.careerOptions(filter),
        index.careerOptions(ProjectFilter.none),
      );
    });

    test('solo abiertos calcula las opciones sobre los abiertos', () {
      const filter = ProjectFilter(onlyOpen: true);
      final skills = index.skillOptions(filter).map((o) => o.key);
      expect(skills, isNot(contains('python')));
      expect(index.careerOptions(filter).last.count, 1);
    });

    test('sin proyectos no hay opciones', () {
      expect(
        ProjectFilterIndex(const []).careerOptions(ProjectFilter.none),
        isEmpty,
      );
    });
  });

  group('reconcile', () {
    test('conserva un filtro que sigue siendo válido', () {
      const filter = ProjectFilter(career: 'diseno', skill: 'figma');
      final result = index.reconcile(filter);
      expect(result.filter, filter);
      expect(result.changed, isFalse);
    });

    test('descarta la habilidad que la carrera nueva ya no ofrece', () {
      const filter = ProjectFilter(career: 'diseno', skill: 'python');
      final result = index.reconcile(filter);
      expect(result.filter, const ProjectFilter(career: 'diseno'));
      expect(result.droppedSkill, isTrue);
      expect(result.droppedCareer, isFalse);
    });

    test('descarta una carrera que desapareció del feed', () {
      const filter = ProjectFilter(career: 'derecho', onlyOpen: true);
      final result = index.reconcile(filter);
      expect(result.filter, const ProjectFilter(onlyOpen: true));
      expect(result.droppedCareer, isTrue);
    });
  });

  group('ProjectFilter', () {
    test('cuenta los filtros activos', () {
      expect(ProjectFilter.none.activeCount, 0);
      expect(ProjectFilter.none.isEmpty, isTrue);
      expect(
        const ProjectFilter(
          career: 'a',
          skill: 'b',
          onlyOpen: true,
        ).activeCount,
        3,
      );
    });
  });

  test('1 000 proyectos con 10 carreras y 15 habilidades filtran en menos de 50 ms', () {
    final many = [
      for (var i = 0; i < 1000; i++)
        aProject(
          id: 'p$i',
          title: 'p$i',
          jobs: [for (var j = 0; j < 10; j++) 'Carrera ${(i + j) % 40}'],
          skills: [
            for (var j = 0; j < 15; j++) 'Habilidad ${(i * 3 + j) % 60}',
          ],
          status: i % 5 == 0 ? 'closed' : 'open',
        ),
    ];
    final big = ProjectFilterIndex(many);
    const filter = ProjectFilter(
      career: 'carrera 7',
      skill: 'habilidad 12',
      onlyOpen: true,
    );

    // La mejor de varias pasadas, para que otra prueba usando la CPU no la vuelva inestable.
    var best = 1 << 30;
    for (var i = 0; i < 5; i++) {
      final watch = Stopwatch()..start();
      big.apply(filter);
      big.careerOptions(filter);
      big.skillOptions(filter);
      watch.stop();
      if (watch.elapsedMilliseconds < best) best = watch.elapsedMilliseconds;
    }

    expect(best, lessThan(50));
  });
}
