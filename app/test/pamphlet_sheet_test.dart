import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/models/pamphlet.dart';
import 'package:spekooh/sheets/pamphlet_sheet.dart';

import 'support/l10n_test_app.dart';

class _RecordingShopRepository implements ShopRepository {
  int? capturedQuantity;
  bool? capturedIsDelivery;
  String? capturedDeliveryAddress;

  @override
  Future<List<Pamphlet>> getPamphlets() => throw UnimplementedError();

  @override
  Future<Pamphlet> getFeaturedPamphlet() => throw UnimplementedError();

  @override
  Future<List<PamphletOrder>> getMyOrders() => throw UnimplementedError();

  @override
  Future<PamphletOrderResult> placeOrder({
    required int pamphletId,
    required bool isDelivery,
    required String phoneNumber,
    int quantity = 1,
    String deliveryAddress = '',
  }) async {
    capturedQuantity = quantity;
    capturedIsDelivery = isDelivery;
    capturedDeliveryAddress = deliveryAddress;
    return const PamphletOrderResult(qrToken: 'test-token', status: 'QR_ISSUED');
  }
}

const _pamphletNoDelivery = Pamphlet(title: 'GCE Chemistry Pack', partner: 'Presbook', priceFcfa: '2,500', priceFcfaValue: 2500);

const _pamphletWithDelivery = Pamphlet(
  title: 'GCE Chemistry Pack',
  partner: 'Presbook',
  priceFcfa: '2,500',
  priceFcfaValue: 2500,
  deliveryAvailable: true,
  deliveryFeeFcfa: 500,
  partnerLocation: 'Molyko, Buea',
);

void main() {
  testWidgets('quantity stepper increases the total charged', (tester) async {
    final repo = _RecordingShopRepository();
    await tester.pumpWidget(l10nTestApp(Scaffold(body: PamphletSheet(pamphlet: _pamphletNoDelivery, repository: repo))));

    expect(find.textContaining('2,500'), findsWidgets);
    await tester.tap(find.byIcon(LucideIcons.plus).hitTestable());
    await tester.pump();
    expect(find.textContaining('5,000'), findsWidgets);

    await tester.tap(find.text('Pay & reserve: 5,000 FCFA'));
    await tester.pump();
    expect(repo.capturedQuantity, 2);
  });

  testWidgets('no delivery toggle is shown when the pamphlet has no delivery option', (tester) async {
    final repo = _RecordingShopRepository();
    await tester.pumpWidget(l10nTestApp(Scaffold(body: PamphletSheet(pamphlet: _pamphletNoDelivery, repository: repo))));

    expect(find.text('Delivery'), findsNothing);
  });

  testWidgets('choosing delivery requires an address before paying', (tester) async {
    final repo = _RecordingShopRepository();
    await tester.pumpWidget(l10nTestApp(Scaffold(body: PamphletSheet(pamphlet: _pamphletWithDelivery, repository: repo))));

    await tester.tap(find.text('Delivery'));
    await tester.pump();
    await tester.tap(find.text('Pay & reserve: 3,000 FCFA'));
    await tester.pump();

    expect(find.text('A delivery address is required.'), findsOneWidget);
    expect(repo.capturedIsDelivery, isNull);
  });

  testWidgets('a filled delivery address is passed through to the real order', (tester) async {
    final repo = _RecordingShopRepository();
    await tester.pumpWidget(l10nTestApp(Scaffold(body: PamphletSheet(pamphlet: _pamphletWithDelivery, repository: repo))));

    await tester.tap(find.text('Delivery'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Molyko, Buea');
    await tester.tap(find.text('Pay & reserve: 3,000 FCFA'));
    await tester.pump();

    expect(repo.capturedIsDelivery, isTrue);
    expect(repo.capturedDeliveryAddress, 'Molyko, Buea');
  });

  testWidgets('pickup shows a real "view on map" link using the real partner location', (tester) async {
    final repo = _RecordingShopRepository();
    await tester.pumpWidget(l10nTestApp(Scaffold(body: PamphletSheet(pamphlet: _pamphletWithDelivery, repository: repo))));

    expect(find.text('Molyko, Buea'), findsOneWidget);
    expect(find.text('View on map'), findsOneWidget);
  });
}
