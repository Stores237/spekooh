import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/sheets/auth_sheet.dart';
import 'package:spekooh/sheets/email_verification_sheet.dart';
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
          'user': {'id': 'fake-id', 'email': 'new@example.com', 'email_verified': true},
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

  testWidgets('the terms checkbox\'s "View Privacy Policy" link opens a real, readable policy', (tester) async {
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage()));

    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Spekooh ("we", "us", "our")'), findsOneWidget);
  });

  testWidgets('registering with no referral code omits it entirely, not as an empty string', (tester) async {
    Map<String, dynamic>? sentBody;
    final mockClient = MockClient((request) async {
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'access': 'fake-access',
          'refresh': 'fake-refresh',
          'user': {'id': 'fake-id', 'email': 'new2@example.com', 'email_verified': true},
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

  testWidgets('registering with an unverifiable email domain shows a specific error, not the generic one', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({"email": ["That email domain doesn't appear to accept mail. Check for a typo."]}),
        400,
        headers: {'content-type': 'application/json'},
      );
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Typo');
    await tester.enterText(fields.at(1), 'typo@gmial.com');
    await tester.enterText(fields.at(2), 'S0mePass!23');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text("That email domain doesn't appear to accept mail. Check for a typo."), findsOneWidget);
    expect(find.text('Registration failed. That email may already be in use.'), findsNothing);
  });

  testWidgets('Create account is disabled until the terms checkbox is checked', (tester) async {
    var requestCount = 0;
    final mockClient = MockClient((request) async {
      requestCount++;
      return http.Response(
        jsonEncode({
          'access': 'fake-access',
          'refresh': 'fake-refresh',
          'user': {'id': 'fake-id', 'email': 'new3@example.com', 'email_verified': true},
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

  testWidgets('registering an unverified account opens the verification sheet automatically', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/register/')) {
        return http.Response(
          jsonEncode({
            'access': 'fake-access',
            'refresh': 'fake-refresh',
            'user': {'id': 'fake-id', 'email': 'unverified@example.com', 'email_verified': false},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Unverified');
    await tester.enterText(fields.at(1), 'unverified@example.com');
    await tester.enterText(fields.at(2), 'S0mePass!23');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
  });

  testWidgets('registering an already-verified account skips the verification sheet', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'access': 'fake-access',
          'refresh': 'fake-refresh',
          'user': {'id': 'fake-id', 'email': 'preverified@example.com', 'email_verified': true},
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
    await tester.enterText(fields.at(0), 'Preverified');
    await tester.enterText(fields.at(1), 'preverified@example.com');
    await tester.enterText(fields.at(2), 'S0mePass!23');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsNothing);
  });

  testWidgets('confirming the emailed code closes the verification sheet and the auth sheet is done', (tester) async {
    String? confirmedCode;
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/register/')) {
        return http.Response(
          jsonEncode({
            'access': 'fake-access',
            'refresh': 'fake-refresh',
            'user': {'id': 'fake-id', 'email': 'confirmnow@example.com', 'email_verified': false},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/verify-email/')) {
        confirmedCode = (jsonDecode(request.body) as Map<String, dynamic>)['code'] as String;
        return http.Response(jsonEncode({'email_verified': true}), 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('not found', 404);
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    var poppedTrue = false;
    await tester.pumpWidget(l10nTestApp(
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AuthSheet(),
              );
              poppedTrue = result == true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Confirm Now');
    await tester.enterText(fields.at(1), 'confirmnow@example.com');
    await tester.enterText(fields.at(2), 'S0mePass!23');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byType(EmailVerificationSheet), matching: find.byType(TextField)),
      '654321',
    );
    await tester.tap(find.widgetWithText(SpekoohButton, 'Verify'));
    await tester.pumpAndSettle();

    expect(confirmedCode, '654321');
    expect(poppedTrue, isTrue); // AuthSheet itself finished successfully afterward
  });

  testWidgets('skipping verification still leaves the account logged in', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/register/')) {
        return http.Response(
          jsonEncode({
            'access': 'fake-access',
            'refresh': 'fake-refresh',
            'user': {'id': 'fake-id', 'email': 'skipverify@example.com', 'email_verified': false},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    var poppedTrue = false;
    await tester.pumpWidget(l10nTestApp(
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AuthSheet(),
              );
              poppedTrue = result == true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Skip Verify');
    await tester.enterText(fields.at(1), 'skipverify@example.com');
    await tester.enterText(fields.at(2), 'S0mePass!23');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(AuthSession.instance.isLoggedIn, isTrue); // register() already granted tokens
    expect(poppedTrue, isTrue);
  });

  testWidgets('a login blocked as unverified offers real recovery, not a dead end', (tester) async {
    var loginAttempts = 0;
    String? confirmedCode;
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/login/')) {
        loginAttempts++;
        if (loginAttempts == 1) {
          return http.Response(jsonEncode({'code': ['email_not_verified']}), 400, headers: {'content-type': 'application/json'});
        }
        return http.Response(
          jsonEncode({
            'access': 'fake-access',
            'refresh': 'fake-refresh',
            'user': {'id': 'fake-id', 'email': 'blocked@example.com', 'email_verified': true},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/verify-email/request-by-email/')) {
        return http.Response(jsonEncode({'detail': 'ok'}), 200, headers: {'content-type': 'application/json'});
      }
      if (request.url.path.endsWith('/verify-email/confirm-by-email/')) {
        confirmedCode = (jsonDecode(request.body) as Map<String, dynamic>)['code'] as String;
        return http.Response(jsonEncode({'detail': 'ok'}), 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('not found', 404);
    });
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage(), httpClient: mockClient));

    await tester.pumpWidget(l10nTestApp(const Scaffold(body: AuthSheet())));
    await tester.enterText(find.byType(TextField).first, 'blocked@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'S0mePass!23');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Please verify your email before logging in.'), findsOneWidget);
    // The recovery code field appeared automatically — no extra tap needed.
    expect(find.text('A new code is on its way.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(2), '111222');
    await tester.tap(find.widgetWithText(SpekoohButton, 'Verify'));
    await tester.pumpAndSettle();

    expect(confirmedCode, '111222');
    expect(find.text('Email verified. Log in again to continue.'), findsOneWidget);

    // The password field is still filled in from before — log in again for real.
    await tester.tap(find.widgetWithText(SpekoohButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(loginAttempts, 2);
    expect(AuthSession.instance.isLoggedIn, isTrue);
  });

  testWidgets('grows its own bottom padding by the keyboard height so a field can never sit behind it', (tester) async {
    // Owner-reported (2026-09-02): the keyboard opened on top of the sheet
    // instead of the sheet shifting to stay above it — showModalBottomSheet
    // doesn't account for MediaQuery.viewInsets on its own, the sheet's own
    // content has to grow its own bottom padding by the keyboard's height.
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage()));

    // A bare Material ancestor, not Scaffold — real usage shows AuthSheet
    // straight from showModalBottomSheet, with no Scaffold in between.
    // Scaffold's own resizeToAvoidBottomInset would consume viewInsets
    // itself and hand descendants a zeroed one, which would pass even the
    // pre-fix code — the opposite of what this needs to catch.
    await tester.pumpWidget(l10nTestApp(const Material(child: AuthSheet())));
    final noKeyboard = tester.widget<Container>(find.byType(Container).first);
    expect((noKeyboard.padding as EdgeInsets).bottom, 26);

    // Simulate a real on-screen keyboard's height, the same way the OS
    // reports one via MediaQuery.viewInsets.bottom.
    await tester.pumpWidget(l10nTestApp(
      MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
        child: const Material(child: AuthSheet()),
      ),
    ));
    final withKeyboard = tester.widget<Container>(find.byType(Container).first);

    expect((withKeyboard.padding as EdgeInsets).bottom, 26 + 300);
  });
}
