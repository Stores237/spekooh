import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/shell/root_shell.dart';

import 'support/mock_repository_locator.dart';

void main() {
  tearDown(() {
    RootShellState.debugShowContributeNudge = true;
  });

  testWidgets('App boots and shows the guest Home tab with bottom nav', (WidgetTester tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    RootShellState.debugShowContributeNudge = false; // dialog would steal taps meant for nav/Settings
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300)); // clears SplashScreen's timed handoff to RootShell
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Papers'), findsOneWidget);
    expect(find.text('Forum'), findsOneWidget);
    expect(find.text('Quizzes'), findsOneWidget);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
  });

  testWidgets('Tapping a bottom nav tab switches the active index', (WidgetTester tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    RootShellState.debugShowContributeNudge = false; // dialog would steal taps meant for nav/Settings
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300)); // clears SplashScreen's timed handoff to RootShell
    await tester.tap(find.text('Papers'));
    await tester.pump();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
  });

  group('Hardware back button (owner-reported, 2026-09-02)', () {
    // RootShell's route is the first (only) one on the root Navigator, so
    // with nothing to pop, Android's real default was to exit the app
    // outright while on a non-Home tab, instead of returning to Home like
    // every other bottom-tab app does.
    testWidgets('on a non-Home tab, the system back gesture returns to Home instead of exiting', (tester) async {
      RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
      RootShellState.debugShowContributeNudge = false;
      await tester.pumpWidget(const SpekoohApp());
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.tap(find.text('Papers'));
      await tester.pump();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);

      final handled = await tester.binding.handlePopRoute();
      await tester.pump();

      expect(handled, isTrue); // PopScope intercepted it — the app did not exit
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
    });

    testWidgets('already on Home, the system back gesture is allowed through (real exit)', (tester) async {
      RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
      RootShellState.debugShowContributeNudge = false;
      await tester.pumpWidget(const SpekoohApp());
      await tester.pump(const Duration(milliseconds: 1300));
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

      final handled = await tester.binding.handlePopRoute();

      // false means nothing in the app consumed it — it falls through to
      // the platform's own default (SystemNavigator.pop / app exit), the
      // one case where that's actually the right behavior.
      expect(handled, isFalse);
    });
  });
}
