import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/sheets/auth_sheet.dart';
import 'package:spekooh/widgets/spekooh_button.dart';

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
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(sentBody?['referral_code'], 'a1b2c3d4');
    expect(sentBody?['terms_accepted'], true);
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
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(sentBody?.containsKey('referral_code'), isFalse);
  });

  testWidgets('Create account is disabled until the terms checkbox is checked', (tester) async {
    var requestCount = 0;
    final mockClient = MockClient((request) async {
      requestCount++;
      return http.Response(
        jsonEncode({
          'access': 'fake-access',
          'refresh': 'fake-refresh',
          'user': {'id': 'fake-id', 'email': 'new3@example.com'},
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
    await tester.enterText(fields.at(1), 'new3@example.com');
    await tester.enterText(fields.at(2), 'S0mePass!23');

    // Unchecked: tapping "Create account" does nothing — no request fired.
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(requestCount, 0);

    // Checked: the same tap now goes through for real.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(requestCount, 1);
  });

  testWidgets('Forgot password link opens the reset sheet, not shown in register mode', (tester) async {
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage()));
    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));

    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsOneWidget);

    await tester.tap(find.text('Back to log in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsNothing);
  });

  testWidgets('full reset flow: request a code, confirm it, land back on the login form', (tester) async {
    final requests = <String>[];
    final mockClient = MockClient((request) async {
      requests.add(request.url.path);
      if (request.url.path.endsWith('/password-reset/')) {
        return http.Response(jsonEncode({'detail': 'ok'}), 200, headers: {'content-type': 'application/json'});
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['email'], 'reset@example.com');
      expect(body['code'], '123456');
      expect(body['new_password'], 'NewPass!456');
      return http.Response(jsonEncode({'detail': 'ok'}), 200, headers: {'content-type': 'application/json'});
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'reset@example.com');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.textContaining('a code is on its way'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '123456');
    await tester.enterText(fields.at(2), 'NewPass!456');
    await tester.tap(find.widgetWithText(SpekoohButton, 'Reset password'));
    await tester.pumpAndSettle();

    // Sheet closed, back on AuthSheet's own login form.
    expect(find.text('Log in to Spekooh'), findsOneWidget);
    expect(requests, ['/api/auth/password-reset/', '/api/auth/password-reset/confirm/']);
  });

  testWidgets('reset flow shows a real error instead of silently doing nothing on an invalid code', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/password-reset/')) {
        return http.Response(jsonEncode({'detail': 'ok'}), 200, headers: {'content-type': 'application/json'});
      }
      return http.Response(jsonEncode({'detail': 'invalid'}), 400, headers: {'content-type': 'application/json'});
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'reset@example.com');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '000000');
    await tester.enterText(fields.at(2), 'NewPass!456');
    await tester.tap(find.widgetWithText(SpekoohButton, 'Reset password'));
    await tester.pumpAndSettle();

    expect(find.text('That code is invalid or has expired.'), findsOneWidget);
    expect(find.widgetWithText(SpekoohButton, 'Reset password'), findsOneWidget); // sheet stayed open
  });
}
