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
}
