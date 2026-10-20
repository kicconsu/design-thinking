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
        'con_deadline': '4',
        'a_tiempo': '3',
      });

      final m = await repo.getTrustMetricsOf('ana');

      expect(m.fulfillment, 88); // (75 + 100) / 2 = 87.5
      expect(m.onTime, 75);
      expect(m.completedProjects, 50);
      expect(m.commitment, 71); // (87.5 + 75 + 50) / 3 = 70.8
      expect(m.hasHistory, isTrue);
    });

    test('un proyecto cerrado sin tareas no cuenta como completado', () async {
      source.participations.add(_participation('ana', 'p1', progress: 100));
      source.deliveries.add({
        'user_id': 'ana',
        'con_deadline': '0',
        'a_tiempo': '0',
      });

      final m = await repo.getTrustMetricsOf('ana');

      // Participó (hay historial), pero sin tareas no hay nada que medir.
      expect(m.hasHistory, isTrue);
      expect(m.fulfillment, isNull);
      expect(m.onTime, isNull);
      expect(m.completedProjects, 0);
    });

    test('solo cuenta a esa persona', () async {
      source.participations.addAll([
        _participation('ana', 'p1', finished: '1', taken: '2', total: '2'),
        _participation('luis', 'p1', finished: '2', taken: '2', total: '2'),
      ]);

      expect((await repo.getTrustMetricsOf('ana')).fulfillment, 50);
    });

    test('sin historial son indicadores vacíos', () async {
      final m = await repo.getTrustMetricsOf('ana');
      expect(m.hasHistory, isFalse);
      expect(m.commitment, isNull);
      expect(m.onTime, isNull);
    });

    test('un id vacío no consulta nada', () async {
      await repo.getTrustMetricsOf('');
      expect(source.participationReads, 0);
      expect(source.deliveryReads, 0);
    });
  });

  group('getCommitmentScores', () {
    test('trae a todos con dos consultas, no una por persona', () async {
      source.participations.addAll([
        _participation(
          'ana',
          'p1',
          finished: '1',
          taken: '2',
          total: '2',
          progress: 0,
        ),
        _participation(
          'ana',
          'p2',
          finished: '3',
          taken: '4',
          total: '4',
          progress: 100,
        ),
        _participation(
          'luis',
          'p1',
          finished: '2',
          taken: '2',
          total: '2',
          progress: 100,
        ),
      ]);

      final scores = await repo.getCommitmentScores(['ana', 'luis', 'ana']);

      // ana: (62.5 cumplimiento + 50 completados) / 2 = 56.25
      expect(scores, {'ana': 56, 'luis': 100});
      expect(source.participationReads, 1);
      expect(source.deliveryReads, 1);
    });

    test('incluye la entrega a tiempo de cada persona', () async {
      source.participations.add(
        _participation(
          'ana',
          'p1',
          finished: '1',
          taken: '2',
          total: '2',
          progress: 100,
        ),
      );
      source.deliveries.add({
        'user_id': 'ana',
        'con_deadline': '2',
        'a_tiempo': '1',
      });

      // (50 cumplimiento + 50 a tiempo + 100 completados) / 3 = 66.7
      expect(await repo.getCommitmentScores(['ana']), {'ana': 67});
    });

    test('un 0 real aparece; quien no tiene historial no', () async {
      source.participations.add(_participation('luis', 'p1', total: '3'));

      final scores = await repo.getCommitmentScores(['luis', 'eva']);

      expect(scores, {'luis': 0});
    });

    test('sin ids no consulta', () async {
      expect(await repo.getCommitmentScores(['', '']), isEmpty);
      expect(source.participationReads, 0);
      expect(source.deliveryReads, 0);
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
