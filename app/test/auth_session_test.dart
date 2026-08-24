import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/token_storage.dart';

import 'support/fake_auth_session.dart';

void main() {
  test('continueAsGuest mints a real, logged-in guest session with the given name', () async {
    final session = buildFakeAuthSession();
    expect(session.isLoggedIn, isFalse);

    await session.continueAsGuest(name: 'Aïcha Mballa');

    expect(session.isLoggedIn, isTrue);
    expect(session.accessToken, 'fake-guest-access-token');
    expect(session.refreshToken, 'fake-guest-refresh-token');
    expect(session.currentUserId, 'fake-guest-id');
  });

  test('continueAsGuest throws AuthException on failure, without logging in', () async {
    final session = AuthSession(
      storage: InMemoryTokenStorage(),
      httpClient: MockClient((request) async => http.Response('server error', 500)),
    );

    await expectLater(
      () => session.continueAsGuest(name: 'Someone'),
      throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.guestFailed)),
    );
    expect(session.isLoggedIn, isFalse);
  });
}
