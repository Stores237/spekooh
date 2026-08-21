import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/ads/rewarded_ad_controller.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_papers_store.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/paper_entry.dart';
import 'package:spekooh/screens/papers/paper_detail_screen.dart';

import 'support/l10n_test_app.dart';

final _entry = PaperEntry(
  id: 1,
  year: 2025,
  system: null,
  track: '',
  status: 'PUBLISHED',
  fileUrl: null,
  createdAt: DateTime(2025, 1, 1),
  subjectTitle: 'Mathematics',
  examTypeName: 'GCE O Level',
);

/// Always reports the daily free-view limit as already hit, so the paywall
/// banner (and "Watch ad" button) render on first build without needing to
/// burn through the real 3-views/day flow.
class _PaywalledPapersRepository implements PapersRepository {
  int adWatchCalls = 0;
  bool grantView = false;

  @override
  Future<PaperEntry> getPaperDetail(int paperId) async => _entry;

  @override
  Future<void> recordView(int paperId) async {
    if (!grantView) {
      throw const PaywallException();
    }
  }

  @override
  Future<void> recordAdWatch() async {
    adWatchCalls++;
    grantView = true; // mirrors the backend: next recordView succeeds.
  }

  List<({int paperId, String reason, String details})> reportCalls = [];
  bool throwAlreadyReported = false;

  @override
  Future<void> reportPaper(int paperId, {required String reason, String details = ''}) async {
    if (throwAlreadyReported) throw const AlreadyReportedException();
    reportCalls.add((paperId: paperId, reason: reason, details: details));
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not used by PaperDetailScreen tests');
}

/// Returns whichever [PaperEntry] it's given from getPaperDetail — the
/// save-offline UI reads `fileUrl` off the resolved detail, not the
/// synchronous paperEntry the screen opens with, so tests exercising it
/// need a real (non-null) fileUrl to come back from the async call.
class _FileBackedPapersRepository implements PapersRepository {
  _FileBackedPapersRepository(this.entry);
  final PaperEntry entry;

  @override
  Future<PaperEntry> getPaperDetail(int paperId) async => entry;

  @override
  Future<void> recordView(int paperId) async {}

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not used by save-offline tests');
}

class _FakeRewardedAdController implements RewardedAdController {
  _FakeRewardedAdController({required this.grantsReward});
  final bool grantsReward;
  int showAdCalls = 0;

  @override
  Future<bool> showAd() async {
    showAdCalls++;
    return grantsReward;
  }
}

Future<void> _pump(WidgetTester tester, PapersRepository repository, RewardedAdController adController) async {
  await tester.pumpWidget(l10nTestApp(
    PaperDetailScreen(paperEntry: _entry, repository: repository, adController: adController),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    OfflinePapersStore.debugSetInstance(OfflinePapersStore());
  });

  testWidgets('paywalled paper shows the banner and a real "Watch ad" button', (tester) async {
    final repository = _PaywalledPapersRepository();
    await _pump(tester, repository, _FakeRewardedAdController(grantsReward: true));

    expect(find.textContaining('Daily free view limit reached'), findsOneWidget);
    expect(find.text('Watch ad for +1 view'), findsOneWidget);
  });

  testWidgets('watching the ad to completion records the watch and clears the paywall', (tester) async {
    final repository = _PaywalledPapersRepository();
    final adController = _FakeRewardedAdController(grantsReward: true);
    await _pump(tester, repository, adController);

    await tester.tap(find.text('Watch ad for +1 view'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(adController.showAdCalls, 1);
    expect(repository.adWatchCalls, 1);
    expect(find.textContaining('Daily free view limit reached'), findsNothing);
    expect(find.text('Watch ad for +1 view'), findsNothing);
  });

  testWidgets('closing the ad early grants nothing and leaves the paywall in place', (tester) async {
    final repository = _PaywalledPapersRepository();
    final adController = _FakeRewardedAdController(grantsReward: false);
    await _pump(tester, repository, adController);

    await tester.tap(find.text('Watch ad for +1 view'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(adController.showAdCalls, 1);
    expect(repository.adWatchCalls, 0);
    expect(find.textContaining('Daily free view limit reached'), findsOneWidget);
    expect(find.text('Ad not completed — no view granted.'), findsOneWidget);
  });

  testWidgets('reporting a paper picks a reason and submits it for real', (tester) async {
    final repository = _PaywalledPapersRepository();
    await _pump(tester, repository, _FakeRewardedAdController(grantsReward: true));

    await tester.tap(find.byTooltip('Report an issue with this paper'));
    await tester.pumpAndSettle();

    expect(find.text('Report an issue'), findsOneWidget);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(repository.reportCalls, hasLength(1));
    expect(repository.reportCalls.single.paperId, 1);
    expect(repository.reportCalls.single.reason, 'WRONG_ANSWERS');
    expect(find.text('Thanks — the Review Team has been notified.'), findsOneWidget);
  });

  testWidgets('cancelling the report dialog sends nothing', (tester) async {
    final repository = _PaywalledPapersRepository();
    await _pump(tester, repository, _FakeRewardedAdController(grantsReward: true));

    await tester.tap(find.byTooltip('Report an issue with this paper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.reportCalls, isEmpty);
  });

  testWidgets('reporting the same paper twice surfaces the already-reported message', (tester) async {
    final repository = _PaywalledPapersRepository()..throwAlreadyReported = true;
    await _pump(tester, repository, _FakeRewardedAdController(grantsReward: true));

    await tester.tap(find.byTooltip('Report an issue with this paper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text("You've already reported this paper."), findsOneWidget);
  });

  testWidgets('PaperDetailScreen renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    final repository = _PaywalledPapersRepository();
    await _pump(tester, repository, _FakeRewardedAdController(grantsReward: true));

    expect(find.text('Corrigé'), findsOneWidget);
    expect(find.text('Marking guide'), findsNothing);
    await tester.tap(find.byTooltip('Signaler un problème avec cette épreuve'));
    await tester.pumpAndSettle();
    expect(find.text('Signaler un problème'), findsOneWidget);
  });

  group('save offline', () {
    final entryWithFile = PaperEntry(
      id: 2,
      year: 2024,
      system: null,
      track: '',
      status: 'PUBLISHED',
      fileUrl: 'https://cdn.example.com/paper2.pdf',
      createdAt: DateTime(2024, 1, 1),
      subjectTitle: 'Biology',
      examTypeName: 'GCE O Level',
    );

    Future<void> pumpWithFile(WidgetTester tester) async {
      await tester.pumpWidget(l10nTestApp(
        PaperDetailScreen(paperEntry: entryWithFile, repository: _FileBackedPapersRepository(entryWithFile), adController: _FakeRewardedAdController(grantsReward: true)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('shows "Save offline" once a scanned file exists, saves for real on tap', (tester) async {
      OfflinePapersStore.debugSetInstance(OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]));
      await pumpWithFile(tester);

      expect(find.text('Save offline'), findsOneWidget);
      expect(find.text('Saved offline'), findsNothing);

      await tester.tap(find.text('Save offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Saved offline'), findsOneWidget);
      expect(find.text('Save offline'), findsNothing);
      expect(OfflinePapersStore.instance.isSaved(2), isTrue);
    });

    testWidgets('tapping again removes it from offline storage', (tester) async {
      OfflinePapersStore.debugSetInstance(OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]));
      await pumpWithFile(tester);

      await tester.tap(find.text('Save offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Saved offline'), findsOneWidget);

      await tester.tap(find.text('Saved offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Save offline'), findsOneWidget);
      expect(OfflinePapersStore.instance.isSaved(2), isFalse);
    });

    testWidgets('a failed download surfaces a real error, not a silent "saved" state', (tester) async {
      OfflinePapersStore.debugSetInstance(OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => throw Exception('offline')));
      await pumpWithFile(tester);

      await tester.tap(find.text('Save offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Save offline'), findsOneWidget);
      expect(find.textContaining('Could not save for offline'), findsOneWidget);
      expect(OfflinePapersStore.instance.isSaved(2), isFalse);
    });
  });
}
