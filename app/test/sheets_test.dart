import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/mock/mock_pamphlets.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/sheets/pamphlet_sheet.dart';
import 'package:spekooh/sheets/paywall_sheet.dart';
import 'package:spekooh/theme/app_theme.dart';

Future<void> _showSheet(WidgetTester tester, Widget sheet) async {
  await tester.pumpWidget(MaterialApp(
    theme: appTheme,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => sheet,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PaywallSheet builds with no exceptions', (tester) async {
    await _showSheet(tester, const PaywallSheet());
    expect(tester.takeException(), isNull);
    expect(find.text('Get Spekooh Pro'), findsOneWidget);
    expect(find.text('Pay 500 FCFA'), findsOneWidget);
  });

  testWidgets('PamphletSheet flips from summary to QR ticket on pay', (tester) async {
    await _showSheet(tester, PamphletSheet(pamphlet: mockFeaturedPamphlet, repository: MockShopRepository()));
    expect(tester.takeException(), isNull);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget);

    await tester.tap(find.textContaining('Pay & reserve'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Pickup ticket ready'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Pickup ticket ready'), findsNothing);
  });
}
