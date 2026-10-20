import 'package:flutter_test/flutter_test.dart';

import 'package:imker/features/trust/domain/models/trust_metrics.dart';

ProjectParticipation _p({
  int finished = 0,
  int taken = 0,
  int total = 0,
  double progress = 0,
}) => ProjectParticipation(
  projectId: 'p',
  tasksFinished: finished,
  tasksTaken: taken,
  totalTasks: total,
  progress: progress,
);

TrustMetrics _calc(
  List<ProjectParticipation> list, {
  OnTimeDeliveries deliveries = const OnTimeDeliveries(),
}) => TrustMetrics.calculate(participations: list, deliveries: deliveries);

void main() {
  group('cumplimiento', () {
    test('tomó 5, terminó 5: 100 %', () {
      expect(_calc([_p(finished: 5, taken: 5, total: 5)]).fulfillment, 100);
    });

    test('tomó 5, terminó 0: 0 %, no "sin datos"', () {
      final m = _calc([_p(taken: 5, total: 5)]);
      expect(m.fulfillment, 0);
    });

    test('un contador desfasado (terminó más de lo que tomó) se acota', () {
      expect(_calc([_p(finished: 7, taken: 5, total: 7)]).fulfillment, 100);
    });

    test('promedia entre proyectos, no entre tareas', () {
      // 1/4 = 25 % y 3/3 = 100 %  ->  62.5 %
      final m = _calc([
        _p(finished: 1, taken: 4, total: 4),
        _p(finished: 3, taken: 3, total: 3),
      ]);
      expect(m.fulfillment, 63);
    });

    test('un proyecto donde no tomó nada no entra en el promedio', () {
      final m = _calc([
        _p(finished: 2, taken: 4, total: 6),
        _p(total: 6), // participó pero no tomó tareas
      ]);
      expect(m.fulfillment, 50);
    });

    test('sin ninguna tarea tomada es nulo, no 0 %', () {
      expect(_calc([_p(total: 6)]).fulfillment, isNull);
    });
  });

  group('entrega a tiempo', () {
    test('cuenta las entregas a tiempo frente a las que tenían fecha', () {
      final m = _calc(
        [_p(taken: 1, total: 1)],
        deliveries: const OnTimeDeliveries(withDeadline: 4, onTime: 3),
      );
      expect(m.onTime, 75);
    });

    test('todas tarde es 0 %', () {
      final m = _calc(
        [_p(taken: 1, total: 1)],
        deliveries: const OnTimeDeliveries(withDeadline: 2, onTime: 0),
      );
      expect(m.onTime, 0);
    });

    test('sin tareas con fecha es nulo, no 0 %', () {
      expect(_calc([_p(taken: 1, total: 1)]).onTime, isNull);
    });

    test('un contador desfasado se acota a 100 %', () {
      final m = _calc(
        [_p(taken: 1, total: 1)],
        deliveries: const OnTimeDeliveries(withDeadline: 2, onTime: 3),
      );
      expect(m.onTime, 100);
    });
  });

  group('proyectos completados', () {
    test('cuenta los que están al 100 % entre los que participó', () {
      final m = _calc([
        _p(total: 4, progress: 100),
        _p(total: 4, progress: 60),
      ]);
      expect(m.completedProjects, 50);
    });

    test('un proyecto cerrado al 60 % no cuenta como completado', () {
      expect(_calc([_p(total: 5, progress: 60)]).completedProjects, 0);
    });

    test('un proyecto sin tareas no cuenta como completado', () {
      expect(_calc([_p(progress: 100)]).completedProjects, 0);
    });
  });

  group('índice general', () {
    test('es el promedio de los indicadores que tienen datos', () {
      final m = _calc(
        [_p(finished: 3, taken: 4, total: 4, progress: 100)],
        deliveries: const OnTimeDeliveries(withDeadline: 2, onTime: 1),
      );
      // (75 cumplimiento + 50 a tiempo + 100 completados) / 3 = 75
      expect(m.commitment, 75);
    });

    test('un indicador nulo no arrastra el general a 0', () {
      final m = _calc([_p(finished: 4, taken: 4, total: 4, progress: 100)]);
      // Sin fechas límite: promedio de cumplimiento (100) y completados (100).
      expect(m.onTime, isNull);
      expect(m.commitment, 100);
    });

    test('se promedia sin redondear antes', () {
      // Cumplimiento 2/3 = 66.67 y completados 0: (66.67 + 0) / 2 = 33.33.
      // Con los redondeos intermedios (67 y 0) saldría 33.5 -> 34.
      final m = _calc([_p(finished: 2, taken: 3, total: 3)]);
      expect(m.fulfillment, 67);
      expect(m.commitment, 33);
    });

    test('puede ser 0 de verdad', () {
      final m = _calc([_p(taken: 3, total: 3)]);
      expect(m.commitment, 0);
      expect(m.hasHistory, isTrue);
    });

    test('con un solo indicador con datos, es ese', () {
      // Participó pero sin tareas tomadas ni fechas: solo "completados".
      final m = _calc([_p(total: 3, progress: 100)]);
      expect(m.fulfillment, isNull);
      expect(m.onTime, isNull);
      expect(m.commitment, 100);
    });
  });

  group('historial', () {
    test('sin participaciones: todo nulo y sin historial', () {
      final m = _calc(const []);
      expect(m.hasHistory, isFalse);
      expect(m.commitment, isNull);
      expect(m.onTime, isNull);
      expect(m.fulfillment, isNull);
      expect(m.completedProjects, isNull);
    });

    test('unas entregas sueltas sin participación no crean historial', () {
      final m = _calc(
        const [],
        deliveries: const OnTimeDeliveries(withDeadline: 3, onTime: 3),
      );
      expect(m.hasHistory, isFalse);
      expect(m.commitment, isNull);
    });

    test('con una participación hay historial aunque no haya números', () {
      final m = _calc([_p()]);
      expect(m.hasHistory, isTrue);
      expect(m.fulfillment, isNull);
      expect(m.onTime, isNull);
    });

    test('TrustMetrics.none es el mismo caso vacío', () {
      expect(TrustMetrics.none.hasHistory, isFalse);
      expect(TrustMetrics.none.commitment, isNull);
    });
  });
}
