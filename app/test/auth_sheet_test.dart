import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/sheets/auth_sheet.dart';

import 'support/l10n_test_app.dart';

void main() {
  testWidgets('registering with a referral code sends it to the real endpoint', (tester) async {
    Map<String, dynamic>? sentBody;
    final mockClient = MockClient((request) async {
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'access': 'fake-access',
          'refresh': 'fake-refresh',
          'user': {'id': 'fake-id', 'email': 'new@example.com'},
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'New User'); // name
    await tester.enterText(fields.at(1), 'new@example.com'); // email
    await tester.enterText(fields.at(2), 'S0mePass!23'); // password
    await tester.enterText(fields.at(3), 'a1b2c3d4'); // referral code

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(sentBody?['referral_code'], 'a1b2c3d4');
  });

  testWidgets('registering with no referral code omits it entirely, not as an empty string', (tester) async {
    Map<String, dynamic>? sentBody;
    final mockClient = MockClient((request) async {
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'access': 'fake-access',
          'refresh': 'fake-refresh',
          'user': {'id': 'fake-id', 'email': 'new2@example.com'},
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'New User');
    await tester.enterText(fields.at(1), 'new2@example.com');
    await tester.enterText(fields.at(2), 'S0mePass!23');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(sentBody?.containsKey('referral_code'), isFalse);
  });
}
