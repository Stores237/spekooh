import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/token_storage.dart';

/// Builds an [AuthSession] whose login/register/refresh calls succeed
/// against a fake response instead of hitting the network — for widget
/// tests, which have no backend to talk to.
AuthSession buildFakeAuthSession() {
  final mockClient = MockClient((request) async {
    if (request.url.path.endsWith('/auth/login/') || request.url.path.endsWith('/auth/register/')) {
      return http.Response(
        jsonEncode({
          'access': 'fake-access-token',
          'refresh': 'fake-refresh-token',
          'user': {'id': 'fake-user-id', 'email': 'test@example.com'},
        }),
        request.url.path.endsWith('/register/') ? 201 : 200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('not found', 404);
  });

  return AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient);
}
