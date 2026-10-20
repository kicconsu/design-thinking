import 'package:imker/core/data/dummy_auth_source.dart';
import 'package:imker/features/auth/domain/models/authentication_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DummyAuthSource', () {
    late DummyAuthSource source;

    setUp(() {
      source = DummyAuthSource();
    });

    test(
      'stores multiple users and restores the matching login session',
      () async {
        await source.signUp(_user('alice@example.com', 'Password1!'));
        await source.signUp(_user('bob@example.com', 'Password2!'));

        expect(
          await source.login(_user('ALICE@example.com', 'Password1!')),
          isTrue,
        );
        expect(await source.restoreSession(), isTrue);
        expect((await source.getLoggedUser())?.email, 'alice@example.com');

        await source.logOut();
        expect(await source.restoreSession(), isFalse);
        expect(await source.getLoggedUser(), isNull);
      },
    );

    test('rejects duplicate accounts and invalid credentials', () async {
      await source.signUp(_user('alice@example.com', 'Password1!'));

      await expectLater(
        source.signUp(_user('ALICE@example.com', 'Password2!')),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        source.login(_user('alice@example.com', 'incorrect')),
        throwsA(isA<StateError>()),
      );
    });

    test('supports anonymous guest session and upgrade', () async {
      expect(await source.signInAnonymously(), isTrue);
      expect(source.isAnonymous, isTrue);
      expect(await source.restoreSession(), isTrue);
      final guest = await source.getLoggedUser();
      expect(guest?.email, 'guest@anonymous.invalid');

      expect(
        await source.upgradeAccount(
          'newuser@example.com',
          'Pass123!',
          'New User',
        ),
        isTrue,
      );
      expect(source.isAnonymous, isFalse);
      final upgraded = await source.getLoggedUser();
      expect(upgraded?.email, 'newuser@example.com');
      expect(upgraded?.name, 'New User');
    });
  });
}

AuthenticationUser _user(String email, String password) =>
    AuthenticationUser(email: email, name: email, password: password);
