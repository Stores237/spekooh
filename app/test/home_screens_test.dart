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
import 'package:spekooh/models/spekooh_user.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/screens/home/home_screen.dart';
import 'package:spekooh/screens/home/logged_in_home_screen.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/shell/root_shell.dart';
import 'package:spekooh/widgets/user_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/l10n_test_app.dart';
import 'support/mock_repository_locator.dart';

void main() {
  tearDown(() {
    OfflinePapersStore.debugSetInstance(OfflinePapersStore());
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('HomeScreen (guest) shows an honest empty state when nothing is published yet', (tester) async {
    await tester.pumpWidget(l10nTestApp(
      HomeScreen(papersRepository: MockPapersRepository(), shopRepository: MockShopRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('No papers published yet. Check back soon.'), findsOneWidget);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget); // real featured pamphlet from the mock
  });

  testWidgets('HomeScreen (guest) contribution card opens Submit', (tester) async {
    var opened = false;
    await tester.pumpWidget(l10nTestApp(
      HomeScreen(papersRepository: MockPapersRepository(), shopRepository: MockShopRepository(), onOpenSubmit: () => opened = true),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text("Got a past paper or report we don't have?"));
    expect(opened, isTrue);
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
    expect(find.text('Free to view (marking guide sold separately)'), findsOneWidget);
  });

  testWidgets('HomeScreen (guest) does not claim a marking guide exists for a free-to-view report', (tester) async {
    // Regression: this card used to show the exam-paper-flavored "marking
    // guide sold separately" copy for reports too, which have no
    // marking-guide/instructor pipeline at all.
    final seeded = PaperEntry(
      id: 9,
      year: 2024,
      system: null,
      track: '',
      status: 'PUBLISHED',
      fileUrl: null,
      createdAt: DateTime(2024, 1, 1),
      examTypeName: 'Internship Report',
      categoryKey: 'reports',
    );
    await tester.pumpWidget(l10nTestApp(
      HomeScreen(papersRepository: MockPapersRepository(seedPublished: [seeded]), shopRepository: MockShopRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('marking guide'), findsNothing);
    expect(find.text('Free to view and download'), findsOneWidget);
  });

  testWidgets('HomeScreen (guest) shows a payment-required note for a gated report', (tester) async {
    final seeded = PaperEntry(
      id: 10,
      year: 2024,
      system: null,
      track: '',
      status: 'PUBLISHED',
      fileUrl: null,
      createdAt: DateTime(2024, 1, 1),
      examTypeName: 'PhD Thesis (Thèse)',
      categoryKey: 'reports',
      requiresUnlock: true,
    );
    await tester.pumpWidget(l10nTestApp(
      HomeScreen(papersRepository: MockPapersRepository(seedPublished: [seeded]), shopRepository: MockShopRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Payment required to view'), findsOneWidget);
  });

  testWidgets('LoggedInHomeScreen builds with real profile/streak/daily-challenge data', (tester) async {
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget); // MockProfileRepository's real (if placeholder) name
    expect(find.text('DAILY CHALLENGE'), findsOneWidget); // uppercased for the two-card daily-challenge layout
    expect(find.text('Group VII the Halogens Quiz'), findsOneWidget); // real quiz.title, own line now
    expect(find.text('8 min'), findsOneWidget); // real quiz.suggestedTime, not a fabricated duration
    expect(find.text('START A STREAK'), findsOneWidget); // MockQuizzesRepository starts at zero — honest, not fabricated
    expect(find.text('Ready offline'), findsNothing); // nothing saved yet — section shouldn't fabricate itself
    // Quick-actions grid: single line (icon + label), a distinct tint each —
    // still every real label, just restyled.
    for (final label in ['Papers', 'Notes', 'Contribute', 'Shop', 'Forum', 'Quizzes']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets(
    'LoggedInHomeScreen header shows the real avatar, not just the initial letter (owner-reported, 2026-09-03)',
    (tester) async {
      // Real bug: Home's header avatar was its own separate, never-updated
      // copy that only ever rendered the user's initial letter — it never
      // checked avatarUrl at all, so a real, set-and-visible-on-Profile
      // avatar never showed up here. UserAvatar (shared with Profile now)
      // fixes this; a widget test's fake network fails near-instantly with
      // no real HTTP stack, so this asserts the same honest-fallback
      // behavior the shared widget guarantees, not a real image render.
      const user = SpekoohUser(
        name: 'Lucien',
        joinDate: 'Joined Aug 2026',
        submissionsCount: 0,
        quizzesCount: 0,
        creditBalance: 0,
        redeemCode: '',
        redeemCodeSubtitle: '',
        avatarUrl: 'https://example.com/avatar.jpg',
      );
      await tester.pumpWidget(l10nTestApp(
        LoggedInHomeScreen(profileRepository: MockProfileRepository(user: user), quizzesRepository: MockQuizzesRepository()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(tester.widget<UserAvatar>(find.byType(UserAvatar)).avatarUrl, 'https://example.com/avatar.jpg');
    },
  );

  testWidgets('LoggedInHomeScreen EN/FR pill actually switches the locale, not just decorative', (tester) async {
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(LocaleController.instance.locale.languageCode, 'en');
    expect(find.text('DAILY CHALLENGE'), findsOneWidget); // English string, confirms starting locale

    await tester.tap(find.text('FR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(LocaleController.instance.locale.languageCode, 'fr');
    expect(find.text('DÉFI DU JOUR'), findsOneWidget); // same section, now in French
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
    RootShellState.debugShowContributeNudge = false; // dialog would steal taps meant for nav/Settings
    addTearDown(() => RootShellState.debugShowContributeNudge = true);
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300)); // clears SplashScreen's timed handoff to RootShell

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
    expect(find.text("Aucune épreuve publiée pour l'instant. Revenez bientôt."), findsOneWidget);
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

    expect(find.text('DÉFI DU JOUR'), findsOneWidget);
    expect(find.text('COMMENCER UNE SÉRIE'), findsOneWidget);
    expect(find.text('DAILY CHALLENGE'), findsNothing);
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
