import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/repositories/notes_repository.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/screens/notes/notes_screen.dart';
import 'package:spekooh/shell/root_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/l10n_test_app.dart';
import 'support/mock_repository_locator.dart';

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    RootShellState.debugShowContributeNudge = true;
  });

  testWidgets('Notes opens from Home and back button returns', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    RootShellState.debugShowContributeNudge = false; // dialog would steal taps meant for nav/Settings
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300)); // clears SplashScreen's timed handoff to RootShell

    await tester.ensureVisible(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Mechanics: Newton’s Laws'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    expect(find.text('Guest'), findsOneWidget);
  });

  testWidgets('NotesScreen renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(NotesScreen(repository: MockNotesRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Notes'), findsOneWidget); // same word in both languages
    expect(find.text('Rechercher des sujets...'), findsOneWidget);
  });

  testWidgets('Subject and Academic level filters narrow the list independently', (tester) async {
    await tester.pumpWidget(l10nTestApp(NotesScreen(repository: MockNotesRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // All 5 seeded notes show with no filter applied.
    expect(find.text('Cell Structure & Function'), findsOneWidget);
    expect(find.text('Acids, Bases & Salts'), findsOneWidget);

    // Filters live in an on-demand sheet behind a trigger button, not two
    // permanent chip rows — open it, pick a subject, apply.
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chemistry'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Acids, Bases & Salts'), findsOneWidget);
    expect(find.text('Cell Structure & Function'), findsNothing);

    // Back to All on subject, then filter by level: O Level (Biology + Chemistry).
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All').first);
    await tester.pump();
    await tester.tap(find.text('O Level'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Acids, Bases & Salts'), findsOneWidget);
    expect(find.text('Cell Structure & Function'), findsOneWidget);
    expect(find.text('Les Nombres Complexes'), findsNothing); // Terminale, not O Level
  });
}
