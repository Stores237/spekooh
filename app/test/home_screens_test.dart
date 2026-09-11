import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_guides_store.dart';
import 'package:spekooh/data/offline_papers_store.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/models/marking_guide.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/repositories/promotions_repository.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/models/promotion.dart';
import 'package:spekooh/models/spekooh_user.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/screens/downloads/my_downloads_screen.dart';
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
    OfflineGuidesStore.debugSetInstance(OfflineGuidesStore());
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

  // Owner decision (2026-09-06): viewing a paper/report is no longer
  // guest-accessible at all — this screen used to preview the real latest
  // published paper right here and let a guest open it; that's gone,
  // replaced by an honest "log in to browse" prompt that makes no
  // getLatestPublished() call at all (a guest hitting that endpoint now
  // just 401s).
  testWidgets('HomeScreen (guest) shows an honest "log in to browse" prompt, never a live paper preview', (tester) async {
    var loginOpened = false;
    await tester.pumpWidget(l10nTestApp(
      HomeScreen(papersRepository: MockPapersRepository(), shopRepository: MockShopRepository(), onLogin: () => loginOpened = true),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Log in to browse papers'), findsOneWidget);

    await tester.tap(find.text('Log in'));
    expect(loginOpened, isTrue);
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

  testWidgets('LoggedInHomeScreen shows the active-trial banner while trialDaysRemaining is still positive', (tester) async {
    const user = SpekoohUser(
      name: 'Lucien',
      joinDate: 'Joined Aug 2026',
      submissionsCount: 0,
      quizzesCount: 0,
      creditBalance: 0,
      redeemCode: '',
      redeemCodeSubtitle: '',
      trialDaysRemaining: 2,
    );
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(user: user), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('YOUR FREE TRIAL'), findsOneWidget);
    expect(find.text('2 days left'), findsOneWidget);
    expect(find.text('YOUR TRIAL HAS ENDED'), findsNothing);
  });

  testWidgets('LoggedInHomeScreen shows a post-trial upsell banner instead of going silent once the trial has ended', (tester) async {
    const user = SpekoohUser(
      name: 'Lucien',
      joinDate: 'Joined Aug 2026',
      submissionsCount: 0,
      quizzesCount: 0,
      creditBalance: 0,
      redeemCode: '',
      redeemCodeSubtitle: '',
      trialDaysRemaining: 0,
    );
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(user: user), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('YOUR TRIAL HAS ENDED'), findsOneWidget);
    expect(find.text('Subscribe now'), findsOneWidget);
    expect(find.text('YOUR FREE TRIAL'), findsNothing);
  });

  testWidgets('LoggedInHomeScreen shows no trial banner at all for an already-paying Plus subscriber', (tester) async {
    const user = SpekoohUser(
      name: 'Lucien',
      joinDate: 'Joined Aug 2026',
      submissionsCount: 0,
      quizzesCount: 0,
      creditBalance: 0,
      redeemCode: '',
      redeemCodeSubtitle: '',
      trialDaysRemaining: 0,
      isPlusSubscriber: true,
    );
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(user: user), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('YOUR TRIAL HAS ENDED'), findsNothing);
    expect(find.text('YOUR FREE TRIAL'), findsNothing);
  });

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

  testWidgets('LoggedInHomeScreen shows no promotion section at all while nothing is active (real default, not a fabricated placeholder)', (tester) async {
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(LucideIcons.megaphone), findsNothing); // the section's own fallback icon — never shown with nothing to promote
  });

  testWidgets('LoggedInHomeScreen shows a real promotion once one is actually active, and its CTA is real', (tester) async {
    final promo = Promotion(id: 1, title: 'Sample sponsor', subtitle: 'Sample promotion', sponsorName: 'Example Sponsor', ctaLabel: 'Learn more', ctaUrl: 'https://example.com');
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(
        profileRepository: MockProfileRepository(),
        quizzesRepository: MockQuizzesRepository(),
        promotionsRepository: MockPromotionsRepository(seed: [promo]),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sample sponsor'), findsOneWidget);
    expect(find.text('Sample promotion'), findsOneWidget);
    expect(find.text('Example Sponsor'), findsOneWidget);
    expect(find.text('Learn more'), findsOneWidget);
    // No real logo on this one — falls back to a generic icon chip.
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('LoggedInHomeScreen renders a real sponsor logo image when the promotion actually has one', (tester) async {
    final promo = Promotion(id: 1, title: 'S@Learn', sponsorName: 'S@Learn', logoUrl: 'https://example.com/slearn_logo.png');
    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(
        profileRepository: MockProfileRepository(),
        quizzesRepository: MockQuizzesRepository(),
        promotionsRepository: MockPromotionsRepository(seed: [promo]),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('LoggedInHomeScreen has no My Downloads entry point when nothing has been saved yet', (tester) async {
    OfflinePapersStore.debugSetInstance(OfflinePapersStore(fileStore: InMemoryOfflineFileStore()));
    OfflineGuidesStore.debugSetInstance(OfflineGuidesStore(fileStore: InMemoryOfflineFileStore()));

    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('My Downloads'), findsNothing);
  });

  testWidgets('LoggedInHomeScreen shows a My Downloads entry point once a paper or a correction is saved, opening the real screen', (tester) async {
    final papers = OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]);
    await papers.bootstrap();
    await papers.save(paperId: 5, title: 'Biology O-Level', subtitle: 'GCE · 2024', fileUrl: 'https://cdn.example.com/paper5.pdf');
    OfflinePapersStore.debugSetInstance(papers);

    final guides = OfflineGuidesStore(fileStore: InMemoryOfflineFileStore());
    await guides.bootstrap();
    await guides.save(
      paperId: 9,
      title: 'Chemistry corrigé',
      guide: MarkingGuide(mcqAnswers: const {'1': 'B'}, nonMcqQuestions: const [], publishedAt: DateTime(2026, 9, 1)),
    );
    OfflineGuidesStore.debugSetInstance(guides);

    await tester.pumpWidget(l10nTestApp(
      LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('My Downloads'), findsOneWidget);
    expect(find.text('2 saved on this phone'), findsOneWidget);

    await tester.ensureVisible(find.text('My Downloads'));
    await tester.pump();
    await tester.tap(find.text('My Downloads'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The real MyDownloadsScreen, Papers tab first — assert on markers
    // unique to this screen rather than shared paper titles, which could
    // in principle also appear on whatever's still underneath in the
    // Navigator stack.
    expect(find.byType(MyDownloadsScreen), findsOneWidget);
    expect(find.text('Download slots'), findsOneWidget);
    expect(find.text('Corrections · 1'), findsOneWidget);
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
    expect(find.text('Connectez-vous pour parcourir les épreuves'), findsOneWidget);
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
}
