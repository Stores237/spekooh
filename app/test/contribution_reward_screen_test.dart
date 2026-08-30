import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/screens/submit/contribution_reward_screen.dart';

import 'support/l10n_test_app.dart';

/// Adapted from a reference rewards-explainer design (owner-provided,
/// 2026-08-30) — real facts only: Spekooh has exactly one currency, bonus
/// credit, plus a real submission-count-based redeem-code tier. No
/// invented points/XP/levels, and no claim that credit has already been
/// earned (it's only awarded once a submission is verified and published).
void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('shows the real reward facts, not a receipt for a specific amount', (tester) async {
    var tapped = false;
    await tester.pumpWidget(l10nTestApp(ContributionRewardScreen(onSubmitAnother: () => tapped = true)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Contribution received'), findsOneWidget);
    expect(find.text('Bonus credit'), findsOneWidget);
    expect(find.text('A real discount code'), findsOneWidget);
    expect(find.text('A quick check first'), findsOneWidget);

    // Never a fabricated specific payout for this action.
    expect(find.textContaining(RegExp(r'\+\d')), findsNothing);

    await tester.tap(find.text('Submit another'));
    expect(tapped, isTrue);
  });

  testWidgets('renders in French once that locale is active', (tester) async {
    await tester.pumpWidget(l10nTestApp(ContributionRewardScreen(onSubmitAnother: () {})));
    await LocaleController.instance.setLocale('fr');
    await tester.pump();

    expect(find.text('Contribution reçue'), findsOneWidget);
    expect(find.text('Bonus de crédit'), findsOneWidget);
    expect(find.text('Contribution received'), findsNothing);
  });
}
