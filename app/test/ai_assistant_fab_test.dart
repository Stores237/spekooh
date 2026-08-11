import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/main.dart';

import 'support/mock_repository_locator.dart';

void main() {
  testWidgets('AI assistant FAB is hidden for guest, appears after login, and opens its sheet', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());
    expect(find.byIcon(Icons.auto_awesome), findsNothing);

    // Log in via Settings.
    await tester.ensureVisible(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
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

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.text('Spekooh Assistant'), findsOneWidget);
    expect(find.text('Explain a hard Physics topic'), findsOneWidget);
  });
}
