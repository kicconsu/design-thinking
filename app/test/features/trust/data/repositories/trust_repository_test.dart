import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:imker/features/trust/data/datasources/i_trust_data_source.dart';
import 'package:imker/features/trust/data/datasources/in_memory_trust_data_source.dart';
import 'package:imker/features/trust/data/repositories/trust_repository.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';

/// Una fila como la devuelve `metricas_compromiso_por_proyecto`: los `numeric`
/// y `bigint` llegan como texto y el `float8` como número.
Map<String, dynamic> _participation(
  String user,
  String project, {
  String finished = '0',
  String taken = '0',
  String total = '0',
  num progress = 0,
}) => {
  'user_id': user,
  'project_id': project,
  'tasks_finished': finished,
  'tasks_taken': taken,
  'total_tasks': total,
  'progress': progress,
};

class _FailingSource implements ITrustDataSource {
  _FailingSource(this.error);
  final Object error;

  @override
  Future<List<Map<String, dynamic>>> readParticipations(List<String> ids) =>
      Future.error(error);

  @override
  Future<List<Map<String, dynamic>>> readDeliveries(List<String> ids) =>
      Future.error(error);
}

void main() {
  late InMemoryTrustDataSource source;
  late TrustRepository repo;

  setUp(() {
    source = InMemoryTrustDataSource();
    repo = TrustRepository(source);
  });

  group('getTrustMetricsOf', () {
    test('lee los números que Roble manda como texto', () async {
      source.participations.addAll([
        _participation(
          'ana',
          'p1',
          finished: '3',
          taken: '4',
          total: '6',
          progress: 100,
        ),
        _participation(
          'ana',
          'p2',
          finished: '1',
          taken: '1',
          total: '4',
          progress: 25.5,
        ),
      ]);
      source.deliveries.add({
        'user_id': 'ana',
        'con_deadline': '5',
        'a_tiempo': '4',
      });

      final m = await repo.getTrustMetricsOf('ana');

      expect(m.commitment, 38); // (50 + 25) / 2 = 37.5
      expect(m.responseRate, 88); // (75 + 100) / 2 = 87.5
      expect(m.onTime, 80);
      expect(m.completedProjects, 50);
      expect(m.hasHistory, isTrue);
    });

    test('el caso de la base real: un proyecto cerrado sin tareas', () async {
      source.participations.add(_participation('ana', 'p1', progress: 100));
      source.deliveries.add({
        'user_id': 'ana',
        'con_deadline': '0',
        'a_tiempo': '0',
      });

      final m = await repo.getTrustMetricsOf('ana');

      // Sin tareas no hay compromiso que medir, aunque el proyecto esté al 100.
      expect(m.commitment, 0);
      expect(m.hasHistory, isFalse);
      expect(m.completedProjects, 100);
    });

    test('solo cuenta a esa persona', () async {
      source.participations.addAll([
        _participation('ana', 'p1', finished: '1', total: '2'),
        _participation('luis', 'p1', finished: '2', total: '2'),
      ]);

      expect((await repo.getTrustMetricsOf('ana')).commitment, 50);
    });

    test('sin historial son indicadores vacíos', () async {
      final m = await repo.getTrustMetricsOf('ana');
      expect(m.hasHistory, isFalse);
      expect(m.onTime, 0);
    });

    test('un id vacío no consulta nada', () async {
      await repo.getTrustMetricsOf('');
      expect(source.participationReads, 0);
      expect(source.deliveryReads, 0);
    });
  });

  group('getCommitmentScores', () {
    test('trae a todos en una sola consulta', () async {
      source.participations.addAll([
        _participation('ana', 'p1', finished: '1', total: '2'),
        _participation('ana', 'p2', finished: '3', total: '4'),
        _participation('luis', 'p1', finished: '2', total: '2'),
      ]);

      final scores = await repo.getCommitmentScores(['ana', 'luis', 'ana']);

      expect(scores, {'ana': 63, 'luis': 100});
      expect(source.participationReads, 1);
      expect(source.deliveryReads, 0);
    });

    test('quien no tiene historial no aparece', () async {
      source.participations.addAll([
        _participation('ana', 'p1', finished: '1', total: '2'),
        _participation('luis', 'p1'),
      ]);

      final scores = await repo.getCommitmentScores(['ana', 'luis', 'eva']);

      expect(scores, {'ana': 50});
    });

    test('sin ids no consulta', () async {
      expect(await repo.getCommitmentScores(['', '']), isEmpty);
      expect(source.participationReads, 0);
    });
  });

  group('errores', () {
    test('sin red', () {
      final failing = TrustRepository(
        _FailingSource(const RobleApiNetworkException('x')),
      );
      expect(
        failing.getTrustMetricsOf('ana'),
        throwsA(
          isA<TrustFailure>().having(
            (e) => e.message,
            'message',
            'Sin conexión. Verifica tu red.',
          ),
        ),
      );
    });

    test('una consulta guardada que no existe se informa, no se disfraza', () {
      final failing = TrustRepository(
        _FailingSource(const RobleApiHttpException(404, 'No existe')),
      );
      expect(
        failing.getCommitmentScores(['ana']),
        throwsA(
          isA<TrustFailure>().having((e) => e.message, 'message', 'No existe'),
        ),
      );
    });

    test('403 pide permiso', () {
      final failing = TrustRepository(
        _FailingSource(const RobleApiHttpException(403, 'no')),
      );
      expect(
        failing.getTrustMetricsOf('ana'),
        throwsA(
          isA<TrustFailure>().having(
            (e) => e.message,
            'message',
            'No tienes permiso para ver estos datos.',
          ),
        ),
      );
    });
  });
}
