import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/widgets/ai_assistant_fab.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/l10n_test_app.dart';
import 'support/mock_repository_locator.dart';

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('AI assistant FAB is hidden for guest, appears after login, and opens its sheet', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());
    expect(find.byIcon(LucideIcons.sparkles), findsNothing);

    // Log in via Settings.
    await tester.ensureVisible(find.byIcon(LucideIcons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.settings));
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

    expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.sparkles));
    await tester.pumpAndSettle();

    expect(find.text('Spekooh Assistant'), findsOneWidget);
    expect(find.text('Explain a hard Physics topic'), findsOneWidget);
  });

  testWidgets('AI assistant sheet renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(
      Scaffold(floatingActionButton: const AIAssistantFab()),
    ));
    await tester.pump();

    await tester.tap(find.byIcon(LucideIcons.sparkles));
    await tester.pumpAndSettle();

    expect(find.text('Assistant Spekooh'), findsOneWidget);
    expect(find.text('Expliquer une notion difficile de Physique'), findsOneWidget);
    expect(find.text('Spekooh Assistant'), findsNothing);
  });
}
