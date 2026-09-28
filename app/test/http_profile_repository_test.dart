// The discount code Profile shows comes from GET /credits/redeem-codes/. A
// code's status only flips to EXPIRED when someone tries to apply it, so an
// ACTIVE row can already be past its expiry: Profile must never present that
// as a usable code.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/api_client.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/repositories/http/http_profile_repository.dart';
import 'package:spekooh/data/token_storage.dart';

HttpProfileRepository _repoWithCodes(List<Map<String, dynamic>> codes) {
  final mockClient = MockClient((request) async {
    final path = request.url.path;
    Object body;
    if (path.endsWith('/auth/me/')) {
      body = {'id': 'u1', 'name': 'Lucien', 'created_at': '2026-08-01T00:00:00Z', 'xp_balance': 480};
    } else if (path.endsWith('/papers/submissions/')) {
      body = <Object>[];
    } else if (path.endsWith('/quizzes/my_stats/')) {
      body = {'quizzes_played': 2};
    } else if (path.endsWith('/credits/redeem-codes/')) {
      body = codes;
    } else {
      return http.Response('not found', 404);
    }
    return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
  });
  return HttpProfileRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));
}

String _in(Duration d) => DateTime.now().toUtc().add(d).toIso8601String();

void main() {
  test('an ACTIVE code that is already past its expiry is not offered as usable', () async {
    final repo = _repoWithCodes([
      {'code': 'STALE00001', 'status': 'ACTIVE', 'value_percent': 20, 'expires_at': _in(const Duration(days: -2))},
    ]);

    final user = await repo.getUser();

    expect(user.redeemCode, isEmpty);
    expect(user.redeemCodeExpiresAt, isNull);
  });

  test('the live code is picked, with its discount and expiry, over an expired one', () async {
    final repo = _repoWithCodes([
      {'code': 'STALE00001', 'status': 'ACTIVE', 'value_percent': 20, 'expires_at': _in(const Duration(days: -2))},
      {'code': 'LIVE000001', 'status': 'ACTIVE', 'value_percent': 10, 'expires_at': _in(const Duration(days: 9))},
    ]);

    final user = await repo.getUser();

    expect(user.redeemCode, 'LIVE000001');
    expect(user.redeemCodeSubtitle, '10% off your next marking guide unlock');
    expect(user.redeemCodeExpiresAt, isNotNull);
    expect(user.redeemCodeExpiresAt!.difference(DateTime.now()).inDays, inInclusiveRange(8, 9));
  });

  test('a used code is never offered', () async {
    final repo = _repoWithCodes([
      {'code': 'USED000001', 'status': 'REDEEMED', 'value_percent': 15, 'expires_at': _in(const Duration(days: 9))},
    ]);

    expect((await repo.getUser()).redeemCode, isEmpty);
  });

  test('points come from the one balance the server reports', () async {
    final user = await _repoWithCodes(const []).getUser();

    expect(user.xpBalance, 480);
  });
}
