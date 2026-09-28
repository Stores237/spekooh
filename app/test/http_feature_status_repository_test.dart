// The app's answer to "is this feature really live?": from the server, cached
// briefly, and cautious ("not live") whenever the server cannot be asked.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/api_client.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/repositories/http/http_feature_status_repository.dart';
import 'package:spekooh/data/token_storage.dart';

HttpFeatureStatusRepository _repo(http.Client client) =>
    HttpFeatureStatusRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: client));

http.Response _ok(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

void main() {
  test('reads payments_live from GET /status/features/', () async {
    String? path;
    final repo = _repo(MockClient((request) async {
      path = request.url.path;
      return _ok({'payments_live': true});
    }));

    final status = await repo.getFeatureStatus();

    expect(status.paymentsLive, isTrue);
    expect(path, endsWith('/status/features/'));
  });

  test('a server that reports payments as not live is believed', () async {
    final repo = _repo(MockClient((request) async => _ok({'payments_live': false})));

    expect((await repo.getFeatureStatus()).paymentsLive, isFalse);
  });

  test('a missing field is treated as not live, never as live', () async {
    final repo = _repo(MockClient((request) async => _ok(<String, dynamic>{})));

    expect((await repo.getFeatureStatus()).paymentsLive, isFalse);
  });

  test('an unreachable or failing server gives the cautious answer instead of throwing', () async {
    final failing = _repo(MockClient((request) async => http.Response('boom', 500)));
    final offline = _repo(MockClient((request) async => throw http.ClientException('offline')));

    expect((await failing.getFeatureStatus()).paymentsLive, isFalse);
    expect((await offline.getFeatureStatus()).paymentsLive, isFalse);
  });

  test('a good answer is cached so every payment screen does not ask again', () async {
    var calls = 0;
    final repo = _repo(MockClient((request) async {
      calls++;
      return _ok({'payments_live': true});
    }));

    await repo.getFeatureStatus();
    await repo.getFeatureStatus();
    await repo.getFeatureStatus();

    expect(calls, 1);
  });

  test('a failed lookup is not cached: the next screen tries again and can succeed', () async {
    var calls = 0;
    final repo = _repo(MockClient((request) async {
      calls++;
      return calls == 1 ? http.Response('boom', 500) : _ok({'payments_live': true});
    }));

    expect((await repo.getFeatureStatus()).paymentsLive, isFalse);
    expect((await repo.getFeatureStatus()).paymentsLive, isTrue);
    expect(calls, 2);
  });
}
