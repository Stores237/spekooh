import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/mock/mock_pamphlets.dart';
import 'package:spekooh/data/repositories/payments_repository.dart';
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
    await _showSheet(tester, PaywallSheet(repository: MockPaymentsRepository()));
    expect(tester.takeException(), isNull);
    expect(find.text('Get Spekooh Pro'), findsOneWidget);
    expect(find.text('Pay 500 FCFA'), findsOneWidget);
  });

  testWidgets('PaywallSheet requires a phone number before it will subscribe', (tester) async {
    await _showSheet(tester, PaywallSheet(repository: MockPaymentsRepository()));
    await tester.tap(find.text('Pay 500 FCFA'));
    await tester.pump();
    expect(find.textContaining('Enter your'), findsOneWidget);
    expect(find.text("You're Pro"), findsNothing);
  });

  testWidgets('PaywallSheet subscribes for real and flips to a confirmed state', (tester) async {
    await _showSheet(tester, PaywallSheet(repository: MockPaymentsRepository()));
    await tester.enterText(find.byType(TextField), '670123456');
    await tester.tap(find.text('Pay 500 FCFA'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text("You're Pro"), findsOneWidget);
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
