// Owner-reported: on the Papers tab, pressing the hardware/system back
// button skipped the taxonomy drill-down (category -> system -> exam type ->
// track -> subject -> paper list) entirely and jumped straight to Home, no
// matter how deep into it the user was. Back should step back one level at a
// time, like every other step-by-step flow in the app, and only fall through
// to "go to Home" once there is truly nothing left to step back through.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/shell/root_shell.dart';
import 'package:spekooh/widgets/bottom_nav.dart';

import 'support/mock_repository_locator.dart';

Finder _papersNavItem() => find.descendant(of: find.byType(BottomNav), matching: find.text('Papers'));

int? _activeTabIndex(WidgetTester tester) => tester.widget<IndexedStack>(find.byType(IndexedStack)).index;

/// Boots the app as a guest, then signs in through the real auth sheet (the
/// same path a user takes) from the Papers tab's own "log in required" view,
/// landing on PapersScreen's first (category) step once signed in.
Future<void> _signInOnPapersTab(WidgetTester tester) async {
  RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
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

  // A successful sign-in always returns to Home first (RootShellState.login),
  // whichever tab the auth sheet was opened from — so Papers has to be
  // reopened, now as a real signed-in user instead of the guest prompt.
  expect(_activeTabIndex(tester), 0);
  await tester.tap(_papersNavItem());
  await tester.pumpAndSettle();

  expect(_activeTabIndex(tester), 1);
  expect(find.text('Secondary'), findsOneWidget); // the category step, not still the guest prompt
}

/// A real system back gesture, same as Android's hardware/gesture back —
/// not a tap on this screen's own on-screen back chevron.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one system back from the deepest step returns to the previous step, not Home', (tester) async {
    await _signInOnPapersTab(tester);

    await tester.tap(find.text('Secondary'));
    await tester.pumpAndSettle();
    expect(find.text('Anglophone'), findsOneWidget); // the system step

    await _systemBack(tester);

    expect(_activeTabIndex(tester), 1); // still on Papers — this is the real bug
    expect(find.text('Secondary'), findsOneWidget); // back to the category step
    expect(find.text('Anglophone'), findsNothing);
  });

  testWidgets('system back steps back through every level of the drill-down, one at a time', (tester) async {
    await _signInOnPapersTab(tester);

    await tester.tap(find.text('Secondary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anglophone'));
    await tester.pumpAndSettle();
    expect(find.text('O Level'), findsOneWidget); // the exam type step

    await tester.tap(find.text('O Level'));
    await tester.pumpAndSettle();
    expect(find.text('Biology'), findsOneWidget); // the subject step

    await tester.tap(find.text('Biology'));
    await tester.pumpAndSettle();
    expect(_activeTabIndex(tester), 1); // the paper list step, still Papers

    // subject step
    await _systemBack(tester);
    expect(_activeTabIndex(tester), 1);
    expect(find.text('Biology'), findsOneWidget);

    // exam type step
    await _systemBack(tester);
    expect(_activeTabIndex(tester), 1);
    expect(find.text('O Level'), findsOneWidget);
    expect(find.text('Biology'), findsNothing);

    // system step
    await _systemBack(tester);
    expect(_activeTabIndex(tester), 1);
    expect(find.text('Anglophone'), findsOneWidget);
    expect(find.text('O Level'), findsNothing);

    // category step — nothing left to step back through inside Papers
    await _systemBack(tester);
    expect(_activeTabIndex(tester), 1);
    expect(find.text('Secondary'), findsOneWidget);
    expect(find.text('Anglophone'), findsNothing);

    // only now does back fall through to the existing "go to Home" behavior
    await _systemBack(tester);
    expect(_activeTabIndex(tester), 0);
  });

  testWidgets('on the very first (category) step, system back goes straight to Home, same as before', (tester) async {
    await _signInOnPapersTab(tester);

    await _systemBack(tester);

    expect(_activeTabIndex(tester), 0);
  });
}
