// "Test mode: payments aren't live yet": shown wherever money would change hands
// while the payment provider is simulated, and gone by itself once it is real.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/mock/mock_pamphlets.dart';
import 'package:spekooh/data/repositories/feature_status_repository.dart';
import 'package:spekooh/data/repositories/payments_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/feature_status.dart';
import 'package:spekooh/sheets/pamphlet_sheet.dart';
import 'package:spekooh/sheets/paywall_sheet.dart';
import 'package:spekooh/widgets/payments_test_mode_notice.dart';

import 'support/l10n_test_app.dart';
import 'support/mock_repository_locator.dart';

const _notice = "Test mode: payments aren't live yet. This works like the real thing, but no money is charged.";

void _useFeatureStatus(FeatureStatusRepository repository) {
  RepositoryLocator.debugSetInstance(buildMockRepositoryLocator(featureStatus: repository));
}

Future<void> _pumpNotice(WidgetTester tester) async {
  await tester.pumpWidget(l10nTestApp(const Scaffold(body: PaymentsTestModeNotice())));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _showSheet(WidgetTester tester, Widget sheet) async {
  await tester.pumpWidget(l10nTestApp(
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => sheet),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

class _Unreachable implements FeatureStatusRepository {
  // The real repository never throws; this stands in for "the server said nothing useful".
  @override
  Future<FeatureStatus> getFeatureStatus() async => const FeatureStatus.unknown();
}

class _Slow implements FeatureStatusRepository {
  final completer = Completer<FeatureStatus>();

  @override
  Future<FeatureStatus> getFeatureStatus() => completer.future;
}

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('is shown while payments are simulated', (tester) async {
    _useFeatureStatus(MockFeatureStatusRepository());

    await _pumpNotice(tester);

    expect(find.text(_notice), findsOneWidget);
  });

  testWidgets('disappears by itself once the server says payments are live', (tester) async {
    _useFeatureStatus(MockFeatureStatusRepository(status: const FeatureStatus(paymentsLive: true)));

    await _pumpNotice(tester);

    expect(find.text(_notice), findsNothing);
  });

  testWidgets('stays visible when the server cannot be reached: the cautious answer', (tester) async {
    _useFeatureStatus(_Unreachable());

    await _pumpNotice(tester);

    expect(find.text(_notice), findsOneWidget);
  });

  testWidgets('is already shown before the server answers, then removed if it says live', (tester) async {
    final slow = _Slow();
    _useFeatureStatus(slow);

    await _pumpNotice(tester);
    expect(find.text(_notice), findsOneWidget); // no flash of an unwarned payment screen

    slow.completer.complete(const FeatureStatus(paymentsLive: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(_notice), findsNothing);
  });

  testWidgets('is translated', (tester) async {
    _useFeatureStatus(MockFeatureStatusRepository());
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');

    await _pumpNotice(tester);

    expect(
      find.text("Mode test : les paiements ne sont pas encore actifs. Tout fonctionne comme en vrai, mais aucun argent n'est débité."),
      findsOneWidget,
    );
  });

  group('sits right where money changes hands', () {
    testWidgets('on the Pro paywall, before and after subscribing', (tester) async {
      _useFeatureStatus(MockFeatureStatusRepository());
      await _showSheet(tester, PaywallSheet(repository: MockPaymentsRepository()));
      expect(find.text(_notice), findsOneWidget);

      await tester.enterText(find.byType(TextField), '670123456');
      await tester.ensureVisible(find.text('Pay 500 FCFA'));
      await tester.tap(find.text('Pay 500 FCFA'));
      await tester.pumpAndSettle();

      expect(find.text("You're Pro"), findsOneWidget);
      expect(find.text(_notice), findsOneWidget); // a subscription taken now is a simulated one
    });

    testWidgets('on the Pro paywall it is gone once payments are live', (tester) async {
      _useFeatureStatus(MockFeatureStatusRepository(status: const FeatureStatus(paymentsLive: true)));

      await _showSheet(tester, PaywallSheet(repository: MockPaymentsRepository()));

      expect(find.text(_notice), findsNothing);
      expect(find.text('Pay 500 FCFA'), findsOneWidget);
    });

    testWidgets('on a pamphlet purchase', (tester) async {
      _useFeatureStatus(MockFeatureStatusRepository());

      await _showSheet(tester, PamphletSheet(pamphlet: mockFeaturedPamphlet, repository: MockShopRepository()));

      expect(find.text(_notice), findsOneWidget);
    });
  });
}
