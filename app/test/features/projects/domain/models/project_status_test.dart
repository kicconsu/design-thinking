import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/projects/domain/models/project_status.dart';

void main() {
  group('ProjectStatus.fromName', () {
    test('traduce los estados que guarda la base de datos', () {
      expect(ProjectStatus.fromName('open'), ProjectStatus.open);
      expect(ProjectStatus.fromName('closed'), ProjectStatus.closed);
      expect(ProjectStatus.open.label, 'Abierto');
      expect(ProjectStatus.closed.label, 'Cerrado');
    });

    test('un estado desconocido no tumba la lista', () {
      expect(ProjectStatus.fromName('archived'), ProjectStatus.open);
      expect(ProjectStatus.fromName(null), ProjectStatus.open);
      expect(ProjectStatus.fromName(''), ProjectStatus.open);
    });
  });
}
