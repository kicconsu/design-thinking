import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

void main() {
  test('inspect RobleApiDataBase methods', () {
    final db = RobleApiDataBase(
      config: RobleApiConfig.fromContract(
        baseUrl: 'https://roble-api.test-openlab.uninorte.edu.co',
        contractId: 'imker_532a660dc4',
      ),
    );
    print('RobleApiDataBase runtime type: ${db.runtimeType}');
  });
}
