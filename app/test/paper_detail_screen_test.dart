import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/ads/rewarded_ad_controller.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_papers_store.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/paper_entry.dart';
import 'package:spekooh/screens/papers/paper_detail_screen.dart';
import 'package:spekooh/screens/papers/report_viewer_screen.dart';

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

/// getPaperDetail returns [gated] until [unlockPaper] is actually called,
/// then [unlocked] — mirrors the backend really flipping requires_unlock/
/// is_unlocked once a real PaperUnlock exists, to catch a screen that
/// never re-fetches after a successful payment.
class _UnlockableReportRepository implements PapersRepository {
  _UnlockableReportRepository({required this.gated, required this.unlocked});
  final PaperEntry gated;
  final PaperEntry unlocked;
  bool paid = false;
  int unlockCalls = 0;

  @override
  Future<PaperEntry> getPaperDetail(int paperId) async => paid ? unlocked : gated;

  @override
  Future<void> recordView(int paperId) async {}

  @override
  Future<int> unlockPaper(int paperId, {String? redeemCode}) async {
    unlockCalls++;
    paid = true;
    return 500;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not used by unlock-refresh tests');
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
  }
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
    expect(find.text('Ad not completed. No view granted.'), findsOneWidget);
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
    expect(find.text('Thanks! The Review Team has been notified.'), findsOneWidget);
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
      // The report cover art is reports-only — an exam paper's file preview
      // never gets one, branded or otherwise.
      expect(find.byType(Image), findsNothing);

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

  group('academic report access control', () {
    Future<void> pumpReport(WidgetTester tester, PaperEntry entry) async {
      OfflinePapersStore.debugSetInstance(OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]));
      await tester.pumpWidget(l10nTestApp(
        PaperDetailScreen(paperEntry: entry, repository: _FileBackedPapersRepository(entry), adController: _FakeRewardedAdController(grantsReward: true)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('a gated PhD/Master\'s report shows the locked message, not the file', (tester) async {
      final gated = PaperEntry(
        id: 3,
        year: 2024,
        system: null,
        track: '',
        status: 'PUBLISHED',
        fileUrl: null, // withheld server-side
        createdAt: DateTime(2024, 1, 1),
        examTypeName: 'PhD Thesis (Thèse)',
        categoryKey: 'reports',
        requiresUnlock: true,
      );
      await pumpReport(tester, gated);

      expect(find.text('This report requires unlocking'), findsOneWidget);
      expect(find.textContaining('PhD and Master\'s theses require payment'), findsOneWidget);
      expect(find.text('View'), findsNothing);
      expect(find.text('Save offline'), findsNothing);

      // The branded cover shows even while locked — it's the report's
      // visual identity, not part of the gated file content.
      final cover = tester.widget<Image>(find.byType(Image));
      expect((cover.image as AssetImage).assetName, 'assets/report_covers/phd_thesis.jpg');
    });

    testWidgets('a free-tier report shows View and pushes the real in-app viewer', (tester) async {
      final free = PaperEntry(
        id: 4,
        year: 2024,
        system: null,
        track: '',
        status: 'PUBLISHED',
        fileUrl: 'https://cdn.example.com/report4.pdf',
        createdAt: DateTime(2024, 1, 1),
        examTypeName: 'Internship Report',
        categoryKey: 'reports',
        requiresUnlock: false,
        isUnlocked: false, // free to view, not yet paid to download
      );
      // A recording NavigatorObserver, not tester.pump()ing all the way —
      // ReportViewerScreen's PdfControllerPinch needs a real platform's pdf
      // plugin to actually render, which a plain widget test doesn't have.
      // What's under test here is the navigation itself: tapping "View"
      // pushes the real viewer with the real fileUrl, not whether pdfx can
      // render in this environment (that's a manual/device concern).
      final observer = _RecordingNavigatorObserver();
      OfflinePapersStore.debugSetInstance(OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]));
      await tester.pumpWidget(l10nTestApp(
        PaperDetailScreen(paperEntry: free, repository: _FileBackedPapersRepository(free), adController: _FakeRewardedAdController(grantsReward: true)),
        navigatorObservers: [observer],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('View'), findsOneWidget);
      expect(find.text('Open scanned paper'), findsNothing);
      // Not download-unlocked yet — the actionable Save-offline row is
      // replaced by a hint, not silently allowed.
      expect(find.text('Save offline'), findsNothing);
      expect(find.textContaining('Unlock below to save a copy'), findsOneWidget);

      final cover = tester.widget<Image>(find.byType(Image));
      expect((cover.image as AssetImage).assetName, 'assets/report_covers/internship_report.jpg');

      await tester.tap(find.text('View'));
      final pushed = observer.lastPushed;
      expect(pushed, isA<MaterialPageRoute>());
      final builtWidget = (pushed as MaterialPageRoute).builder(tester.element(find.byType(PaperDetailScreen)));
      expect(builtWidget, isA<ReportViewerScreen>());
      expect((builtWidget as ReportViewerScreen).fileUrl, 'https://cdn.example.com/report4.pdf');
    });

    testWidgets('once download-unlocked, Save offline works normally for a report', (tester) async {
      final unlocked = PaperEntry(
        id: 5,
        year: 2024,
        system: null,
        track: '',
        status: 'PUBLISHED',
        fileUrl: 'https://cdn.example.com/report5.pdf',
        createdAt: DateTime(2024, 1, 1),
        examTypeName: 'Internship Report',
        categoryKey: 'reports',
        requiresUnlock: false,
        isUnlocked: true,
      );
      await pumpReport(tester, unlocked);

      expect(find.text('Save offline'), findsOneWidget);
      expect(find.textContaining('Unlock below to save a copy'), findsNothing);

      await tester.tap(find.text('Save offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Saved offline'), findsOneWidget);
      expect(OfflinePapersStore.instance.isSaved(5), isTrue);
    });

    testWidgets('paying to unlock a gated report grants access immediately, without reopening the screen', (tester) async {
      // Regression: _unlock() used to only set _unlockedAmount and never
      // refetch _detail, so requiresUnlock/isUnlocked stayed at their
      // pre-payment values — a just-paid gated report kept showing the
      // locked message until the user left and came back.
      final gated = PaperEntry(
        id: 6,
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
      final unlockedAfterPayment = PaperEntry(
        id: 6,
        year: 2024,
        system: null,
        track: '',
        status: 'PUBLISHED',
        fileUrl: 'https://cdn.example.com/report6.pdf',
        createdAt: DateTime(2024, 1, 1),
        examTypeName: 'PhD Thesis (Thèse)',
        categoryKey: 'reports',
        requiresUnlock: false,
        isUnlocked: true,
      );
      final repository = _UnlockableReportRepository(gated: gated, unlocked: unlockedAfterPayment);
      OfflinePapersStore.debugSetInstance(OfflinePapersStore(fileStore: InMemoryOfflineFileStore(), download: (url) async => [1, 2, 3]));
      await tester.pumpWidget(l10nTestApp(
        PaperDetailScreen(paperEntry: gated, repository: repository, adController: _FakeRewardedAdController(grantsReward: true)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('This report requires unlocking'), findsOneWidget);
      expect(find.text('View'), findsNothing);

      await tester.tap(find.text('Unlock: 500 FCFA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repository.unlockCalls, 1);
      expect(find.text('This report requires unlocking'), findsNothing);
      expect(find.text('View'), findsOneWidget);
    });
  });
}
