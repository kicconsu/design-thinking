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

void main() {
  group('compromiso', () {
    test('promedia, entre proyectos, terminadas frente al total', () {
      // 5/10 = 50 % y 3/4 = 75 %  ->  62.5 %
      final m = TrustMetrics.calculate(
        participations: [_p(finished: 5, total: 10), _p(finished: 3, total: 4)],
      );
      expect(m.commitment, 63);
    });

    test('es un promedio de proyectos, no de tareas', () {
      // Sumando tareas daría 11/110 = 10 %; por proyecto es (100 + 0) / 2.
      final m = TrustMetrics.calculate(
        participations: [
          _p(finished: 1, total: 1),
          _p(finished: 0, total: 109),
        ],
      );
      expect(m.commitment, 50);
    });

    test('un proyecto sin tareas no entra en el promedio (no es un 0)', () {
      final m = TrustMetrics.calculate(
        participations: [_p(finished: 2, total: 4), _p()],
      );
      expect(m.commitment, 50);
    });

    test('sin proyectos, o solo sin tareas, es 0 y no hay historial', () {
      expect(TrustMetrics.calculate(participations: const []).commitment, 0);
      final m = TrustMetrics.calculate(participations: [_p(), _p()]);
      expect(m.commitment, 0);
      expect(m.hasHistory, isFalse);
    });

    test('un contador desfasado no pasa de 100 %', () {
      final m = TrustMetrics.calculate(
        participations: [_p(finished: 9, total: 4)],
      );
      expect(m.commitment, 100);
    });

    test('commitmentOf es lo mismo que el índice del cálculo completo', () {
      final list = [_p(finished: 1, total: 3), _p(finished: 2, total: 2)];
      expect(
        TrustMetrics.commitmentOf(list),
        TrustMetrics.calculate(participations: list).commitment,
      );
    });
  });

  group('tasa de respuesta', () {
    test('promedia, entre proyectos, terminadas frente a tomadas', () {
      final m = TrustMetrics.calculate(
        participations: [
          _p(finished: 1, taken: 4, total: 8),
          _p(finished: 3, taken: 3, total: 6),
        ],
      );
      expect(m.responseRate, 63); // (25 + 100) / 2
    });

    test('lo soltado cuenta como tomado y sin terminar', () {
      final m = TrustMetrics.calculate(
        participations: [_p(finished: 2, taken: 5, total: 5)],
      );
      expect(m.responseRate, 40);
    });

    test('un proyecto sin tareas tomadas no entra', () {
      final m = TrustMetrics.calculate(
        participations: [_p(finished: 1, taken: 2, total: 2), _p(total: 3)],
      );
      expect(m.responseRate, 50);
    });
  });

  group('entrega a tiempo', () {
    test('es a tiempo entre las terminadas con fecha límite', () {
      final m = TrustMetrics.calculate(
        participations: const [],
        deliveries: const OnTimeDeliveries(withDeadline: 4, onTime: 3),
      );
      expect(m.onTime, 75);
    });

    test('sin entregas con fecha límite es 0, sin dividir entre cero', () {
      final m = TrustMetrics.calculate(
        participations: const [],
        deliveries: const OnTimeDeliveries(),
      );
      expect(m.onTime, 0);
    });
  });

  group('proyectos completados', () {
    test('son los que están al 100 % entre todos en los que participó', () {
      final m = TrustMetrics.calculate(
        participations: [
          _p(progress: 100),
          _p(progress: 100),
          _p(progress: 40),
          _p(progress: 0),
        ],
      );
      expect(m.completedProjects, 50);
    });

    test('sin proyectos es 0', () {
      expect(
        TrustMetrics.calculate(participations: const []).completedProjects,
        0,
      );
    });
  });
}
