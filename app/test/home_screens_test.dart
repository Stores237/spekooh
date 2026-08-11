import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/screens/home/home_screen.dart';
import 'package:spekooh/screens/home/logged_in_home_screen.dart';
import 'package:spekooh/theme/app_theme.dart';
import 'package:spekooh/main.dart';

import 'support/mock_repository_locator.dart';

void main() {
  testWidgets('HomeScreen (guest) builds with no exceptions', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: const HomeScreen()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Mathématiques · Baccalauréat 2025'), findsOneWidget);
  });

  testWidgets('LoggedInHomeScreen builds with no exceptions', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: const LoggedInHomeScreen()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Kkk'), findsOneWidget);
    expect(find.text('Daily challenge'), findsOneWidget);
  });

  testWidgets('Full login flow: Settings -> Log in -> LoggedInHomeScreen on Home tab', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());

    await tester.ensureVisible(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    await tester.ensureVisible(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    // AuthSheet is now open (login mode: email field, then password field) — fill in and submit.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'test@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.text('Log in').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Kkk'), findsOneWidget);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
  });
}
