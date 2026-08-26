import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/repositories/notes_repository.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/screens/notes/notes_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/l10n_test_app.dart';
import 'support/mock_repository_locator.dart';

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('Notes opens from Home and back button returns', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300)); // clears SplashScreen's timed handoff to RootShell

    await tester.ensureVisible(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Mechanics — Newton’s Laws'), findsOneWidget);

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
}
