import 'package:roble/roble.dart';

import 'package:imker/core/roble/roble_client.dart';

/// Base de datos de Roble que no sale a la red.
///
/// La app decide si hay una sesión real mirando el [RobleClient] registrado
/// (`isLoggedIn`, `currentUserId`). Las pruebas de integración registran uno
/// que apunta a este doble para que esas preguntas tengan respuesta, pero
/// todos los datasources que lee la app son dobles de `integration_test/support`: nada
/// llama a `read`, `create`, `update` ni a ningún otro método que viaje por
/// HTTP. La dirección `127.0.0.1:1` es una segunda barrera: si alguien lo
/// intentara, la conexión se rechaza sin llegar a ningún servidor.
class FakeRobleDb extends RobleApiDataBase {
  FakeRobleDb({required this.userId})
    : super(
        config: RobleApiConfig.fromContract(
          baseUrl: 'http://127.0.0.1:1',
          contractId: 'test_ab12cd34ef',
        ),
        storage: RobleMemoryStorage(),
      );

  /// El `user_id` que tendrá la sesión cuando alguien entre.
  final String userId;

  /// Lo enciende [FakeAuthenticationSource] al iniciar sesión.
  bool signedIn = false;

  @override
  String? get currentUserId => signedIn ? userId : null;

  @override
  bool get isLoggedIn => signedIn;

  @override
  bool get isAnonymous => false;
}

/// Un [RobleClient] cuyo `db` es un [FakeRobleDb].
RobleClient fakeRobleClient(FakeRobleDb db) => RobleClient.withDatabase(db);
