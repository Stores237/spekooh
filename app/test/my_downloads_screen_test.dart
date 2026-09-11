import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_guides_store.dart';
import 'package:spekooh/data/offline_papers_store.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/models/marking_guide.dart';
import 'package:spekooh/models/spekooh_user.dart';
import 'package:spekooh/screens/downloads/my_downloads_screen.dart';

import 'support/l10n_test_app.dart';

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

  testWidgets('the XP redemption card is shown honestly as coming soon, not a fabricated balance', (tester) async {
    await tester.pumpWidget(l10nTestApp(MyDownloadsScreen(profileRepository: MockProfileRepository(user: _freeUser))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('+1 slot for 3 days'), findsOneWidget);
    expect(find.textContaining('coming soon'), findsOneWidget);
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
