// The root shell asks the server, on every sign-in, whether this account still
// has to accept the current Terms of Service, and blocks with the prompt if so.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/models/terms_status.dart';
import 'package:spekooh/shell/root_shell.dart';
import 'package:spekooh/sheets/terms_update_dialog.dart';
import 'package:spekooh/widgets/bottom_nav.dart';

import 'support/mock_repository_locator.dart';

Finder _papersNavItem() => find.descendant(of: find.byType(BottomNav), matching: find.text('Papers'));

/// Boots the app as a guest, then signs in through the real auth sheet, the
/// same path a user takes.
Future<void> _signIn(WidgetTester tester, MockProfileRepository profile) async {
  RepositoryLocator.debugSetInstance(buildMockRepositoryLocator(profile: profile));
  RootShellState.debugShowContributeNudge = false; // this dialog would steal taps
  addTearDown(() => RootShellState.debugShowContributeNudge = true);
  await tester.pumpWidget(const SpekoohApp());
  await tester.pump(const Duration(milliseconds: 1300)); // clears SplashScreen's timed handoff to RootShell

  await tester.tap(_papersNavItem());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Log in'));
  await tester.pumpAndSettle();
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'test@example.com');
  await tester.enterText(fields.at(1), 'password123');
  await tester.tap(find.text('Log in').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an account that still has to accept the Terms is stopped by the prompt after signing in', (tester) async {
    final profile = MockProfileRepository(termsStatus: const TermsStatus(needsAcceptance: true, version: '2099-01-01'));

    await _signIn(tester, profile);

    expect(find.byType(TermsUpdateDialog), findsOneWidget);
    expect(find.text("We've updated our Terms of Service"), findsOneWidget);
  });

  testWidgets('accepting records the version the server named and lets them into the app', (tester) async {
    final profile = MockProfileRepository(termsStatus: const TermsStatus(needsAcceptance: true, version: '2099-01-01'));
    await _signIn(tester, profile);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();

    expect(profile.acceptedTermsVersions, ['2099-01-01']);
    expect(find.byType(TermsUpdateDialog), findsNothing);
    expect(AuthSession.instance.isLoggedIn, isTrue);
  });

  testWidgets('logging out from the prompt signs them out and records nothing', (tester) async {
    final profile = MockProfileRepository(termsStatus: const TermsStatus(needsAcceptance: true, version: '2099-01-01'));
    await _signIn(tester, profile);

    await tester.tap(find.text('Log out instead'));
    await tester.pumpAndSettle();

    expect(AuthSession.instance.isLoggedIn, isFalse);
    expect(profile.acceptedTermsVersions, isEmpty);
    expect(find.byType(TermsUpdateDialog), findsNothing);
  });

  testWidgets('an account that has already accepted is never prompted', (tester) async {
    await _signIn(tester, MockProfileRepository());

    expect(find.byType(TermsUpdateDialog), findsNothing);
    expect(AuthSession.instance.isLoggedIn, isTrue);
  });

  testWidgets('a failed status check never blocks the app', (tester) async {
    await _signIn(tester, _OfflineTermsCheck());

    expect(find.byType(TermsUpdateDialog), findsNothing);
    expect(AuthSession.instance.isLoggedIn, isTrue);
  });
}

class _OfflineTermsCheck extends MockProfileRepository {
  @override
  Future<TermsStatus> getTermsStatus() async => throw Exception('offline');
}
