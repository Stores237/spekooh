import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/token_storage.dart';

import 'support/fake_auth_session.dart';

void main() {
  test('mintGuestAccessToken returns a real token for the given name, without logging the app in', () async {
    // This is deliberately not a login: a guest contributing a paper isn't
    // the same as an app-wide "logged in" state — see SubmitScreen, the
    // only caller.
    final session = buildFakeAuthSession();
    expect(session.isLoggedIn, isFalse);

    final token = await session.mintGuestAccessToken(name: 'Aïcha Mballa');

    expect(token, 'fake-guest-access-token');
    expect(session.isLoggedIn, isFalse);
    expect(session.accessToken, isNull);
    expect(session.refreshToken, isNull);
    expect(session.currentUserId, isNull);
  });

  test('mintGuestAccessToken throws AuthException on failure', () async {
    final session = AuthSession(
      storage: InMemoryTokenStorage(),
      httpClient: MockClient((request) async => http.Response('server error', 500)),
    );

    await expectLater(
      () => session.mintGuestAccessToken(name: 'Someone'),
      throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.guestFailed)),
    );
    expect(session.isLoggedIn, isFalse);
  });
}
