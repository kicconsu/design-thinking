import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/projects/data/datasources/in_memory_project_data_source.dart';

void main() {
  test('las marcas de tiempo salen del reloj inyectado', () async {
    final now = DateTime.utc(2026, 3, 4, 5, 6);
    final source = InMemoryProjectDataSource(null, () => now);

    final request = await source.createJoinRequest({
      'project_id': 'p1',
      'user_id': 'ana',
    });

    expect(request['createdAt'], now.toIso8601String());
    expect(request['updatedAt'], now.toIso8601String());
  });
}
