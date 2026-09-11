import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_guides_store.dart';
import 'package:spekooh/data/offline_papers_store.dart';
import 'package:spekooh/data/repositories/payments_repository.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/models/marking_guide.dart';
import 'package:spekooh/models/spekooh_user.dart';
import 'package:spekooh/screens/downloads/my_downloads_screen.dart';

import 'support/l10n_test_app.dart';

/// Returns each user in [steps] in order, one per call, then stays on the
/// last one — mirrors a real profile refetch actually seeing state a
/// previous call just changed (e.g. right after a real redemption).
class _StepProfileRepository implements ProfileRepository {
  _StepProfileRepository(this.steps);
  final List<SpekoohUser> steps;
  int _calls = 0;

  @override
  Future<SpekoohUser> getUser() async {
    final user = steps[_calls < steps.length ? _calls : steps.length - 1];
    _calls++;
    return user;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not used by these tests');
}

const _freeUser = SpekoohUser(
  name: 'Lucien',
  joinDate: 'Joined Aug 2026',
  submissionsCount: 0,
  quizzesCount: 0,
  creditBalance: 0,
  redeemCode: '',
  redeemCodeSubtitle: '',
);

const _plusUser = SpekoohUser(
  name: 'Lucien',
  joinDate: 'Joined Aug 2026',
  submissionsCount: 0,
  quizzesCount: 0,
  creditBalance: 0,
  redeemCode: '',
  redeemCodeSubtitle: '',
  isPlusSubscriber: true,
);

final _guide = MarkingGuide(mcqAnswers: const {'1': 'B'}, nonMcqQuestions: const [], publishedAt: DateTime(2026, 9, 1));

void main() {
  setUp(() {
    OfflinePapersStore.debugSetInstance(OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]));
    OfflineGuidesStore.debugSetInstance(OfflineGuidesStore(fileStore: InMemoryOfflineFileStore()));
  });

  testWidgets('an honest empty state shows for a free account with nothing saved yet', (tester) async {
    await tester.pumpWidget(l10nTestApp(MyDownloadsScreen(profileRepository: MockProfileRepository(user: _freeUser))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('0 saved on this phone'), findsOneWidget);
    expect(find.text('Papers · 0'), findsOneWidget);
    expect(find.text('Corrections · 0'), findsOneWidget);
    expect(find.textContaining('No downloads yet'), findsOneWidget);
    expect(find.text('0 OF 3 USED'), findsOneWidget);
  });

  testWidgets('a real saved paper shows in the Papers tab with a working remove button', (tester) async {
    await OfflinePapersStore.instance.save(paperId: 5, title: 'Biology O-Level', subtitle: 'GCE · 2024', fileUrl: 'https://cdn.example.com/p5.pdf');
    await tester.pumpWidget(l10nTestApp(MyDownloadsScreen(profileRepository: MockProfileRepository(user: _freeUser))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Biology O-Level'), findsOneWidget);
    expect(find.text('1 OF 3 USED'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.trash2));
    await tester.pump();

    expect(find.text('Biology O-Level'), findsNothing);
    expect(find.text('0 OF 3 USED'), findsOneWidget);
    expect(OfflinePapersStore.instance.isSaved(5), isFalse);
  });

  testWidgets('switching to the Corrections tab shows a real saved guide, not a paper', (tester) async {
    await OfflineGuidesStore.instance.save(paperId: 9, title: 'Chemistry corrigé', guide: _guide);
    await tester.pumpWidget(l10nTestApp(MyDownloadsScreen(profileRepository: MockProfileRepository(user: _freeUser))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Chemistry corrigé'), findsNothing); // Papers tab is shown first
    await tester.tap(find.text('Corrections · 1'));
    await tester.pump();

    expect(find.text('Chemistry corrigé'), findsOneWidget);
    expect(find.text('1 OF 3 USED'), findsOneWidget);
  });

  testWidgets('the XP redemption card shows a real balance, disabled below the real cost', (tester) async {
    await tester.pumpWidget(l10nTestApp(MyDownloadsScreen(profileRepository: MockProfileRepository(user: _freeUser))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('+1 slot for 3 days'), findsOneWidget);
    expect(find.text('You have 0 XP'), findsOneWidget);
    expect(find.text('Redeem'), findsOneWidget);

    await tester.tap(find.text('Redeem'));
    await tester.pump();
    // Disabled (0 XP < 250) — no call was made, no SnackBar, still 0 XP shown.
    expect(find.text('You have 0 XP'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('redeeming with enough real XP spends it and reflects the real active bonus immediately', (tester) async {
    final xpUser = SpekoohUser(
      name: 'Lucien',
      joinDate: 'Joined Aug 2026',
      submissionsCount: 0,
      quizzesCount: 0,
      creditBalance: 0,
      redeemCode: '',
      redeemCodeSubtitle: '',
      xpBalance: 250,
    );
    final activeUser = SpekoohUser(
      name: 'Lucien',
      joinDate: 'Joined Aug 2026',
      submissionsCount: 0,
      quizzesCount: 0,
      creditBalance: 0,
      redeemCode: '',
      redeemCodeSubtitle: '',
      xpBalance: 0,
      hasActiveSlotBonus: true,
    );
    final profileRepository = _StepProfileRepository([xpUser, activeUser]);
    await tester.pumpWidget(l10nTestApp(
      MyDownloadsScreen(profileRepository: profileRepository, paymentsRepository: MockPaymentsRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('You have 250 XP'), findsOneWidget);

    await tester.tap(find.text('Redeem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Bonus slot active'), findsOneWidget);
    expect(find.text('Redeem'), findsNothing); // no button once already active
    expect(find.text('0 OF 4 USED'), findsOneWidget); // effective cap now 3 + 1
  });

  testWidgets('a real redemption failure (e.g. a race with the balance) shows the real backend message, not a silent no-op', (tester) async {
    final xpUser = SpekoohUser(
      name: 'Lucien',
      joinDate: 'Joined Aug 2026',
      submissionsCount: 0,
      quizzesCount: 0,
      creditBalance: 0,
      redeemCode: '',
      redeemCodeSubtitle: '',
      xpBalance: 250,
    );
    final payments = MockPaymentsRepository()..mockRedeemError = InsufficientXPError('You need 250 XP to redeem this. You have 0.');
    await tester.pumpWidget(l10nTestApp(
      MyDownloadsScreen(profileRepository: MockProfileRepository(user: xpUser), paymentsRepository: payments),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Redeem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('You need 250 XP to redeem this. You have 0.'), findsOneWidget);
  });

  testWidgets('a Kawlo Plus subscriber sees no slots cap and no upsell banner', (tester) async {
    await tester.pumpWidget(l10nTestApp(MyDownloadsScreen(profileRepository: MockProfileRepository(user: _plusUser))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Download slots'), findsNothing);
    expect(find.textContaining('unlimited downloads'), findsNothing);
  });

  testWidgets('a free account sees both the slots card and the Kawlo Plus upsell', (tester) async {
    await tester.pumpWidget(l10nTestApp(MyDownloadsScreen(profileRepository: MockProfileRepository(user: _freeUser))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Download slots'), findsOneWidget);
    expect(find.textContaining('unlimited downloads'), findsOneWidget);
    expect(find.text('500 FCFA/mo'), findsOneWidget);
  });
}
