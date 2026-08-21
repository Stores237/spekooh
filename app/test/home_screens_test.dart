import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_papers_store.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/models/paper_entry.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/screens/home/home_screen.dart';
import 'package:spekooh/screens/home/logged_in_home_screen.dart';
import 'package:spekooh/main.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/l10n_test_app.dart';
import 'support/mock_repository_locator.dart';

void main() {
  tearDown(() {
    OfflinePapersStore.debugSetInstance(OfflinePapersStore());
  });

  testWidgets('HomeScreen (guest) shows an honest empty state when nothing is published yet', (tester) async {
    await tester.pumpWidget(l10nTestApp(
      HomeScreen(papersRepository: MockPapersRepository(), shopRepository: MockShopRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('No papers published yet — check back soon.'), findsOneWidget);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget); // real featured pamphlet from the mock
  });

  testWidgets('HomeScreen (guest) shows the real latest published paper when one exists', (tester) async {
    final seeded = PaperEntry(
      id: 7,
      year: 2025,
      system: null,
      track: '',
      status: 'PUBLISHED',
      fileUrl: null,
      createdAt: DateTime(2025, 1, 1),
      subjectTitle: 'Mathématiques',
      examTypeName: 'Baccalauréat',
    );
    PaperEntry? opened;
    await tester.pumpWidget(l10nTestApp(
      HomeScreen(
        papersRepository: MockPapersRepository(seedPublished: [seeded]),
        shopRepository: MockShopRepository(),
        onOpenPaper: (p) => opened = p,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Mathématiques · Baccalauréat 2025'), findsOneWidget);

    await tester.tap(find.textContaining('Mathématiques · Baccalauréat 2025'));
    await tester.pump();
    expect(opened?.id, 7);
  });

  testWidgets('LoggedInHomeScreen builds with real profile/streak/daily-challenge data', (tester) async {
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget); // MockProfileRepository's real (if placeholder) name
    expect(find.text('Daily challenge'), findsOneWidget);
    expect(find.text('START A STREAK'), findsOneWidget); // MockQuizzesRepository starts at zero — honest, not fabricated
    expect(find.text('Ready offline'), findsNothing); // nothing saved yet — section shouldn't fabricate itself
  });

  testWidgets('LoggedInHomeScreen shows a real "Ready offline" section once a paper is actually saved', (tester) async {
    final store = OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]);
    await store.bootstrap();
    await store.save(paperId: 5, title: 'Biology O-Level', subtitle: 'GCE · 2024', fileUrl: 'https://cdn.example.com/paper5.pdf');
    OfflinePapersStore.debugSetInstance(store);

    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ready offline'), findsOneWidget);
    expect(find.text('Downloads · 1'), findsOneWidget);
    expect(find.text('Biology O-Level'), findsOneWidget);
    expect(find.text('OFFLINE READY'), findsOneWidget);
  });

  testWidgets('Full login flow: Settings -> Log in -> LoggedInHomeScreen on Home tab', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());

    await tester.ensureVisible(find.byIcon(LucideIcons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.settings));
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
    expect(find.text('Guest'), findsOneWidget); // MockProfileRepository's real (placeholder) name
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
  });

  testWidgets('HomeScreen (guest) renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(
      HomeScreen(papersRepository: MockPapersRepository(), shopRepository: MockShopRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Invité'), findsOneWidget);
    expect(find.text("Aucune épreuve publiée pour l'instant — revenez bientôt."), findsOneWidget);
    expect(find.text('Guest'), findsNothing);
  });

  testWidgets('LoggedInHomeScreen renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Défi du jour'), findsOneWidget);
    expect(find.text('COMMENCER UNE SÉRIE'), findsOneWidget);
    expect(find.text('Daily challenge'), findsNothing);
  });

  testWidgets('the "Ready offline" section renders in French once that locale is active', (tester) async {
    final store = OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]);
    await store.bootstrap();
    await store.save(paperId: 5, title: 'Biologie O-Level', subtitle: 'GCE · 2024', fileUrl: 'https://cdn.example.com/paper5.pdf');
    OfflinePapersStore.debugSetInstance(store);

    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Disponible hors ligne'), findsOneWidget);
    expect(find.text('Téléchargements · 1'), findsOneWidget);
    expect(find.text('PRÊT HORS LIGNE'), findsOneWidget);
    expect(find.text('Ready offline'), findsNothing);
  });
}
