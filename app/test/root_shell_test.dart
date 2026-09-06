import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/shell/root_shell.dart';
import 'package:spekooh/widgets/bottom_nav.dart';

import 'support/mock_repository_locator.dart';

/// LoggedInHomeScreen has its own "Papers" quick-access tile alongside the
/// bottom nav's own "Papers" label — scope to the nav bar specifically so
/// tapping it isn't ambiguous once logged in.
Finder _papersNavItem() => find.descendant(of: find.byType(BottomNav), matching: find.text('Papers'));

/// Owner decision (2026-09-06): viewing a paper/report — the Papers tab's
/// entire purpose — is no longer guest-accessible at all, only
/// contributing one still is. These exercise the tab-level gate directly
/// (RootShellState._buildPapersTab), rather than PapersScreen itself,
/// which a guest should never even reach.
void main() {
  testWidgets('a guest tapping the Papers tab sees a real "log in" prompt, never the papers taxonomy', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    RootShellState.debugShowContributeNudge = false; // dialog would steal the tap meant for the Papers tab
    addTearDown(() => RootShellState.debugShowContributeNudge = true);
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300)); // clears SplashScreen's timed handoff to RootShell

    await tester.tap(_papersNavItem());
    await tester.pumpAndSettle();

    expect(find.text('Log in to continue'), findsOneWidget);
    expect(find.text('Search by year...'), findsNothing); // PapersScreen's own taxonomy search never renders
  });

  testWidgets('logging in from the Papers tab\'s prompt reveals the real papers taxonomy', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    RootShellState.debugShowContributeNudge = false;
    addTearDown(() => RootShellState.debugShowContributeNudge = true);
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300));

    await tester.tap(_papersNavItem());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'test@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.text('Log in').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Log in to continue'), findsNothing);
    // Real login flips RootShell back to the Home tab (index 0) — same
    // behavior _openAuthSheet already has everywhere else it's used, not
    // specific to this test. Follow it back to Papers to see the real screen.
    await tester.tap(_papersNavItem());
    await tester.pumpAndSettle();
    expect(find.text('Log in to continue'), findsNothing);
  });
}
