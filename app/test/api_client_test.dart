import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/api_client.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/token_storage.dart';

void main() {
  test('postMultipart uses bearerTokenOverride instead of the session\'s own token', () async {
    // The scenario this protects: a guest contributing a paper must never
    // accidentally ride on some other real token this session happens to
    // hold — see AuthSession.mintGuestAccessToken.
    String? capturedAuthHeader;
    final mockClient = MockClient((request) async {
      capturedAuthHeader = request.headers['Authorization'];
      return http.Response(jsonEncode({'id': 1}), 201);
    });
    final authSession = AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient);
    authSession.accessToken = 'real-logged-in-token';
    final client = ApiClient(authSession: authSession, httpClient: mockClient, baseUrl: 'http://test/api');

    await client.postMultipart(
      '/papers/submissions/',
      fileFieldName: 'uploaded_file',
      fileBytes: const [1, 2, 3],
      fileName: 'test.pdf',
      bearerTokenOverride: 'guest-token',
    );

    expect(capturedAuthHeader, 'Bearer guest-token');
  });

  test('postMultipart falls back to the session\'s own token with no override', () async {
    String? capturedAuthHeader;
    final mockClient = MockClient((request) async {
      capturedAuthHeader = request.headers['Authorization'];
      return http.Response(jsonEncode({'id': 1}), 201);
    });
    final authSession = AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient);
    authSession.accessToken = 'real-logged-in-token';
    final client = ApiClient(authSession: authSession, httpClient: mockClient, baseUrl: 'http://test/api');

    await client.postMultipart(
      '/papers/submissions/',
      fileFieldName: 'uploaded_file',
      fileBytes: const [1, 2, 3],
      fileName: 'test.pdf',
    );

    expect(capturedAuthHeader, 'Bearer real-logged-in-token');
  });

  test('postMultipart with a bearerTokenOverride never attempts a refresh-retry on 401', () async {
    // A guest token has no refresh token behind it — retrying with this
    // session's own (real, logged-in) refresh token would silently swap
    // the guest's identity for whoever's real session this is.
    var requestCount = 0;
    final mockClient = MockClient((request) async {
      requestCount++;
      return http.Response('unauthorized', 401);
    });
    final authSession = AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient);
    authSession.accessToken = 'real-logged-in-token';
    authSession.refreshToken = 'real-refresh-token';
    final client = ApiClient(authSession: authSession, httpClient: mockClient, baseUrl: 'http://test/api');

    await expectLater(
      () => client.postMultipart(
        '/papers/submissions/',
        fileFieldName: 'uploaded_file',
        fileBytes: const [1, 2, 3],
        fileName: 'test.pdf',
        bearerTokenOverride: 'expired-guest-token',
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
    expect(requestCount, 1);
  });
}
