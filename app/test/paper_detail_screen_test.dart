import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/ads/rewarded_ad_controller.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/models/paper_entry.dart';
import 'package:spekooh/screens/papers/paper_detail_screen.dart';
import 'package:spekooh/theme/app_theme.dart';

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
      throw PaywallException('Daily free view limit reached. Watch a rewarded ad or upgrade to Pro.');
    }
  }

  @override
  Future<void> recordAdWatch() async {
    adWatchCalls++;
    grantView = true; // mirrors the backend: next recordView succeeds.
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not used by PaperDetailScreen tests');
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
  await tester.pumpWidget(MaterialApp(
    theme: appTheme,
    home: PaperDetailScreen(paperEntry: _entry, repository: repository, adController: adController),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
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
}
