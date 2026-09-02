import 'dart:convert';

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

  group('refreshAccessToken (security hardening, 2026-09-02)', () {
    // The backend now rotates the refresh token on every use and
    // blacklists the one just spent — a stolen refresh token becomes
    // single-use instead of valid for its whole lifetime. That only works
    // if this client actually persists the new one; otherwise its own
    // next refresh attempt presents the now-blacklisted old token and
    // forces a real logout.
    test('persists the rotated refresh token from a real response, not just the access token', () async {
      final storage = InMemoryTokenStorage();
      final session = AuthSession(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(jsonDecode(request.body), {'refresh': 'old-refresh'});
          return http.Response(
            jsonEncode({'access': 'new-access', 'refresh': 'new-refresh'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      session.refreshToken = 'old-refresh';

      final succeeded = await session.refreshAccessToken();

      expect(succeeded, isTrue);
      expect(session.accessToken, 'new-access');
      expect(session.refreshToken, 'new-refresh');
      expect(await storage.read('spekooh_refresh_token'), 'new-refresh');
    });

    test('keeps the current refresh token if the response has no new one', () async {
      // Backward-compatible fallback (e.g. if rotation is ever disabled
      // again on the backend) — never leaves refreshToken null after a
      // successful refresh just because a rotated one wasn't present.
      final session = AuthSession(
        storage: InMemoryTokenStorage(),
        httpClient: MockClient(
          (request) async => http.Response(jsonEncode({'access': 'new-access'}), 200, headers: {'content-type': 'application/json'}),
        ),
      );
      session.refreshToken = 'old-refresh';

      final succeeded = await session.refreshAccessToken();

      expect(succeeded, isTrue);
      expect(session.accessToken, 'new-access');
      expect(session.refreshToken, 'old-refresh');
    });

    test('a blacklisted/expired refresh token fails cleanly, without touching stored tokens', () async {
      final session = AuthSession(
        storage: InMemoryTokenStorage(),
        httpClient: MockClient((request) async => http.Response('{"detail": "Token is blacklisted"}', 401)),
      );
      session.refreshToken = 'stale-refresh';

      final succeeded = await session.refreshAccessToken();

      expect(succeeded, isFalse);
      expect(session.refreshToken, 'stale-refresh'); // caller (ApiClient) decides what happens next, e.g. a real logout
    });
  });
}
