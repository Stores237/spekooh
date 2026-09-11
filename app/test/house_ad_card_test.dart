import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/house_ad_visibility.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/widgets/house_ad_card.dart';

import 'support/l10n_test_app.dart';

void main() {
  tearDown(() {
    HouseAdVisibility.debugSetInstance(HouseAdVisibility(storage: InMemoryTokenStorage()));
  });

  testWidgets('shows the real, generalized copy — not school-specific', (tester) async {
    HouseAdVisibility.debugSetInstance(HouseAdVisibility(storage: InMemoryTokenStorage()));
    await tester.pumpWidget(l10nTestApp(const Scaffold(body: HouseAdCard())));
    await tester.pump();
    await tester.pump();

    expect(find.text('SPONSORED'), findsOneWidget);
    expect(find.text('Advertise your business on Kawlo'), findsOneWidget);
    expect(find.text('Advertise your school on Kawlo'), findsNothing); // the old, school-only copy
    expect(find.text('Why this ad?'), findsOneWidget);
  });

  testWidgets('dismissing hides it immediately and persists across a fresh instance', (tester) async {
    final storage = InMemoryTokenStorage();
    HouseAdVisibility.debugSetInstance(HouseAdVisibility(storage: storage));
    await tester.pumpWidget(l10nTestApp(const Scaffold(body: HouseAdCard())));
    await tester.pump();
    await tester.pump();

    expect(find.text('Advertise your business on Kawlo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('houseAdDismissButton')));
    await tester.pump();

    expect(find.text('Advertise your business on Kawlo'), findsNothing);

    // A real, separate check against the same storage sees it too — not
    // just in-memory widget state that would reappear on the next launch.
    expect(await HouseAdVisibility(storage: storage).isDismissed(), isTrue);
  });

  testWidgets('never flashes the card before a real dismissed check resolves', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('house_ad_dismissed', 'true');
    HouseAdVisibility.debugSetInstance(HouseAdVisibility(storage: storage));
    await tester.pumpWidget(l10nTestApp(const Scaffold(body: HouseAdCard())));
    await tester.pump();
    await tester.pump();

    expect(find.text('Advertise your business on Kawlo'), findsNothing);
  });

  testWidgets('"Why this ad?" shows a real, honest explanation', (tester) async {
    HouseAdVisibility.debugSetInstance(HouseAdVisibility(storage: InMemoryTokenStorage()));
    await tester.pumpWidget(l10nTestApp(const Scaffold(body: HouseAdCard())));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Why this ad?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not a targeted ad'), findsOneWidget);
  });
}
