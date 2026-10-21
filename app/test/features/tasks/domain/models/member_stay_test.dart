import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/tasks/domain/models/member_stay.dart';

void main() {
  MemberStay stay(
    String id, {
    bool active = true,
    DateTime? joined,
    int finished = 0,
  }) => MemberStay(
    id: id,
    isActive: active,
    joinedAt: joined,
    finished: finished,
  );

  group('current', () {
    test('sin estancias es null', () {
      expect(MemberStay.current(const []), isNull);
    });

    test('prefiere la activa aunque haya otra más reciente', () {
      final active = stay('a', joined: DateTime(2026, 1, 1));
      final left = stay('b', active: false, joined: DateTime(2026, 6, 1));
      expect(MemberStay.current([left, active])!.id, 'a');
    });

    test('sin ninguna activa toma la más reciente', () {
      final old = stay('a', active: false, joined: DateTime(2026, 1, 1));
      final recent = stay('b', active: false, joined: DateTime(2026, 6, 1));
      expect(MemberStay.current([old, recent])!.id, 'b');
      expect(MemberStay.current([recent, old])!.id, 'b');
    });

    test('una fecha desconocida pierde frente a una conocida', () {
      final dated = stay('a', active: false, joined: DateTime(2026, 1, 1));
      final undated = stay('b', active: false);
      expect(MemberStay.current([undated, dated])!.id, 'a');
      expect(MemberStay.current([dated, undated])!.id, 'a');
    });
  });

  group('finishedFor', () {
    test('con una sola estancia es el total', () {
      final only = stay('a');
      expect(MemberStay.finishedFor(only, [only], 4), 4);
    });

    test('resta lo que ya anotaron las otras estancias', () {
      final old = stay('a', active: false, finished: 3);
      final now = stay('b');
      expect(MemberStay.finishedFor(now, [old, now], 5), 2);
    });

    test('nunca es negativo', () {
      final old = stay('a', active: false, finished: 3);
      final now = stay('b');
      expect(MemberStay.finishedFor(now, [old, now], 1), 0);
    });
  });
}
