import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_guides_store.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/marking_guide.dart';
import 'package:spekooh/screens/papers/marking_guide_screen.dart';
import 'package:spekooh/sheets/auth_sheet.dart';

import 'support/l10n_test_app.dart';

final _guide = MarkingGuide(
  mcqAnswers: const {'1': 'B'},
  nonMcqQuestions: const [
    MarkingGuideQuestion(questionType: 'SHORT_ANSWER', text: 'Name the site of aerobic respiration.', answer: 'The mitochondrion.'),
  ],
  publishedAt: DateTime(2026, 9, 1),
);

void main() {
  setUp(() {
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage())..accessToken = 'fake-access-token');
    OfflineGuidesStore.debugSetInstance(OfflineGuidesStore(fileStore: InMemoryOfflineFileStore()));
  });

  testWidgets('shows an honest message when no guide has been published yet', (tester) async {
    final repo = MockPapersRepository()..mockGuideError = const GuideNotPublishedException();
    await tester.pumpWidget(l10nTestApp(
      MarkingGuideScreen(paperId: 1, paperTitle: 'Biology', repository: repo, profileRepository: MockProfileRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining("isn't ready yet"), findsOneWidget);
    expect(find.text('Save offline'), findsNothing);
  });

  testWidgets('shows an honest locked message when this user has not unlocked it', (tester) async {
    final repo = MockPapersRepository()..mockGuideError = const GuideLockedException();
    await tester.pumpWidget(l10nTestApp(
      MarkingGuideScreen(paperId: 1, paperTitle: 'Biology', repository: repo, profileRepository: MockProfileRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Unlock'), findsOneWidget);
  });

  testWidgets('renders the real MCQ and written sections once a guide is unlocked', (tester) async {
    final repo = MockPapersRepository()..mockGuide = _guide;
    await tester.pumpWidget(l10nTestApp(
      MarkingGuideScreen(paperId: 1, paperTitle: 'Biology', repository: repo, profileRepository: MockProfileRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Multiple choice answers'), findsOneWidget);
    expect(find.text('1: B'), findsOneWidget);
    expect(find.text('Written answers'), findsOneWidget);
    expect(find.text('Name the site of aerobic respiration.'), findsOneWidget);
    expect(find.text('The mitochondrion.'), findsOneWidget);
  });

  testWidgets('Save offline actually saves the real content, and toggles back off on a second tap', (tester) async {
    final repo = MockPapersRepository()..mockGuide = _guide;
    await tester.pumpWidget(l10nTestApp(
      MarkingGuideScreen(paperId: 1, paperTitle: 'Biology', repository: repo, profileRepository: MockProfileRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Save offline'), findsOneWidget);
    await tester.tap(find.text('Save offline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Saved offline'), findsOneWidget);
    expect(OfflineGuidesStore.instance.isSaved(1), isTrue);
    expect(OfflineGuidesStore.instance.guides.single.mcqAnswers, {'1': 'B'});

    await tester.tap(find.text('Saved offline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Save offline'), findsOneWidget);
    expect(OfflineGuidesStore.instance.isSaved(1), isFalse);
  });

  testWidgets('a guest tapping Save offline sees the real login sheet first, saves nothing', (tester) async {
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage()));
    final repo = MockPapersRepository()..mockGuide = _guide;
    await tester.pumpWidget(l10nTestApp(
      MarkingGuideScreen(paperId: 1, paperTitle: 'Biology', repository: repo, profileRepository: MockProfileRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Save offline'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthSheet), findsOneWidget);
    expect(OfflineGuidesStore.instance.isSaved(1), isFalse);
  });
}
