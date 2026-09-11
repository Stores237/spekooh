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

  testWidgets(
    'the real Scaffold is extendBody: true (so the notch shows real content behind the bar)',
    (tester) async {
      RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
      await tester.pumpWidget(const SpekoohApp());
      await tester.pump(const Duration(milliseconds: 1300));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.extendBody, isTrue);
    },
  );

  testWidgets(
    'extendBody + each tab\'s own bare SafeArea() is enough on its own — no manual bottom padding needed '
    'on top (owner, 2026-09-11 second pass: the first extendBody attempt in #111 ALSO added its own '
    'Padding, double-counting on top of the automatic inset extendBody already feeds every tab\'s own '
    'SafeArea() via MediaQuery — that stacked into a real ~150px dead-space gap above the bar. This '
    'reproduces just that layering with a plain tab, not real screens, since real Home content hits '
    'pre-existing, unrelated font-metric overflows at test-only viewport sizes.)',
    (tester) async {
      const barHeight = 76.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            extendBody: true,
            body: SafeArea(
              bottom: false,
              // A tab screen shaped like the app's real ones: its own
              // nested Scaffold + bare SafeArea() (default bottom: true).
              child: Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(child: Container(color: Colors.blue)),
                      Container(key: const Key('lastContent'), height: 20, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: Container(height: barHeight, color: Colors.white),
          ),
        ),
      );
      await tester.pump();

      final barTopY = tester.getTopLeft(find.byType(Container).last).dy;
      final lastContentBottomY = tester.getBottomLeft(find.byKey(const Key('lastContent'))).dy;

      // Flush against the bar (Expanded fills exactly down to it via the
      // inner SafeArea's own automatic inset) — not stranded ~76px above
      // it from a second, manually-added compensation.
      expect((barTopY - lastContentBottomY).abs(), lessThan(1));
    },
  );
}
