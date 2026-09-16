import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/qr_vault_pin.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/pamphlet.dart';
import 'package:spekooh/screens/shop/qr_vault_screen.dart';

import 'support/l10n_test_app.dart';

class _FakeShopRepository implements ShopRepository {
  _FakeShopRepository(this.orders);
  final List<PamphletOrder> orders;

  @override
  Future<List<PamphletOrder>> getMyOrders() => Future.value(orders);

  @override
  Future<List<Pamphlet>> getPamphlets() => throw UnimplementedError();

  @override
  Future<Pamphlet> getFeaturedPamphlet() => throw UnimplementedError();

  @override
  Future<PamphletOrderResult> placeOrder({required int pamphletId, required bool isDelivery, required String phoneNumber}) =>
      throw UnimplementedError();
}

final _order = PamphletOrder(
  id: 7,
  pamphletTitle: 'Probatoire Philosophy Pamphlet',
  status: 'QR_ISSUED',
  amountPaid: 7500,
  createdAt: DateTime(2026, 9, 16),
  qrToken: 'realtoken1234567890',
  qrRedeemUrl: 'https://spekooh-staging.onrender.com/redeem/realtoken1234567890/',
  partnerName: 'Librairie Centrale',
  partnerLocation: 'Avenue Kennedy, Douala',
  partnerPhone: '670000099',
  partnerWhatsapp: '670000098',
);

void main() {
  tearDown(() {
    QrVaultPin.debugSetInstance(QrVaultPin(storage: InMemoryTokenStorage()));
  });

  testWidgets('a first-time visitor must set a PIN before seeing any real ticket data', (tester) async {
    QrVaultPin.debugSetInstance(QrVaultPin(storage: InMemoryTokenStorage()));
    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    expect(find.text('Set a QR Vault PIN'), findsOneWidget);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsNothing);
    expect(find.text('Librairie Centrale'), findsNothing);
  });

  testWidgets('setting and confirming a PIN reveals the real ticket', (tester) async {
    QrVaultPin.debugSetInstance(QrVaultPin(storage: InMemoryTokenStorage()));
    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter the same PIN again to confirm.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    // The real ticket detail, not just the picker list -- with only one
    // order, QrVaultScreen auto-selects it (a real
    // WidgetsBinding.addPostFrameCallback, hence pumpAndSettle here).
    expect(find.text('Avenue Kennedy, Douala'), findsOneWidget);
    expect(await QrVaultPin.instance.hasPin(), isTrue);
  });

  testWidgets('a returning visitor with the wrong PIN never sees the ticket', (tester) async {
    final storage = InMemoryTokenStorage();
    await QrVaultPin(storage: storage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: storage));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    expect(find.text('Enter your QR Vault PIN'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Probatoire Philosophy Pamphlet'), findsNothing);
    expect(find.textContaining('Wrong PIN'), findsOneWidget);
  });

  testWidgets('the correct PIN reveals the real ticket, including bookshop contact info', (tester) async {
    final storage = InMemoryTokenStorage();
    await QrVaultPin(storage: storage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: storage));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '4321');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget);
    expect(find.text('Librairie Centrale'), findsOneWidget);
    expect(find.text('Avenue Kennedy, Douala'), findsOneWidget);
  });
}
