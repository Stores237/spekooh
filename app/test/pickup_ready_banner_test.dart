import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/notifications_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/models/notification_item.dart';
import 'package:spekooh/models/pamphlet.dart';
import 'package:spekooh/widgets/icon_chip.dart';
import 'package:spekooh/widgets/pickup_ready_banner.dart';

import 'support/l10n_test_app.dart';

class _FakeNotifications implements NotificationsRepository {
  _FakeNotifications(this.items);
  final List<NotificationItem> items;

  @override
  Future<List<NotificationItem>> getNotifications() => Future.value(items);

  @override
  Future<void> markAllRead() async {}
}

class _FakeShop implements ShopRepository {
  _FakeShop(this.orders, {this.fail = false});
  final List<PamphletOrder> orders;
  final bool fail;

  @override
  Future<List<PamphletOrder>> getMyOrders() => fail ? Future.error(Exception('offline')) : Future.value(orders);

  @override
  Future<List<Pamphlet>> getPamphlets() => throw UnimplementedError();

  @override
  Future<Pamphlet> getFeaturedPamphlet() => throw UnimplementedError();

  @override
  Future<PamphletOrderResult> placeOrder({
    required int pamphletId,
    required bool isDelivery,
    required String phoneNumber,
    int quantity = 1,
    String deliveryAddress = '',
  }) =>
      throw UnimplementedError();
}

NotificationItem _readyNotification(int orderId, {bool isRead = false}) => NotificationItem(
      icon: Icons.qr_code,
      tint: IconChipTint.green,
      title: 'Your pickup ticket is ready',
      body: 'Pamphlet is ready',
      time: 'now',
      isRead: isRead,
      link: 'qr-vault/$orderId',
    );

PamphletOrder _order(int id, String status) => PamphletOrder(
      id: id,
      pamphletTitle: 'Physics Pack',
      status: status,
      amountPaid: 3000,
      createdAt: DateTime(2026, 9, 20),
      qrToken: 'token$id',
    );

Future<void> _pump(WidgetTester tester, {required List<NotificationItem> notifications, required _FakeShop shop}) async {
  await tester.pumpWidget(l10nTestApp(Scaffold(body: PickupReadyBanner(repository: _FakeNotifications(notifications), shopRepository: shop))));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows for an unread ready notification whose ticket is still awaiting pickup', (tester) async {
    await _pump(tester, notifications: [_readyNotification(7)], shop: _FakeShop([_order(7, 'QR_ISSUED')]));
    expect(find.text('Your pickup ticket is ready'), findsOneWidget);
  });

  testWidgets('disappears once the ticket has been used, even though its notification is still unread', (tester) async {
    // Owner-reported (2026-09-21): the popup stayed after the ticket was consumed.
    await _pump(tester, notifications: [_readyNotification(7)], shop: _FakeShop([_order(7, 'RELEASED')]));
    expect(find.text('Your pickup ticket is ready'), findsNothing);
  });

  testWidgets('does not show for an expired or disputed order either', (tester) async {
    await _pump(tester, notifications: [_readyNotification(7)], shop: _FakeShop([_order(7, 'EXPIRED')]));
    expect(find.text('Your pickup ticket is ready'), findsNothing);
    await _pump(tester, notifications: [_readyNotification(7)], shop: _FakeShop([_order(7, 'DISPUTED')]));
    expect(find.text('Your pickup ticket is ready'), findsNothing);
  });

  testWidgets('skips a used ticket and shows the one that is still waiting', (tester) async {
    await _pump(
      tester,
      notifications: [_readyNotification(7), _readyNotification(9)],
      shop: _FakeShop([_order(7, 'RELEASED'), _order(9, 'QR_ISSUED')]),
    );
    expect(find.text('Your pickup ticket is ready'), findsOneWidget);
  });

  testWidgets('shows nothing when the order cannot be confirmed as pending', (tester) async {
    await _pump(tester, notifications: [_readyNotification(7)], shop: _FakeShop([]));
    expect(find.text('Your pickup ticket is ready'), findsNothing);
    await _pump(tester, notifications: [_readyNotification(7)], shop: _FakeShop([], fail: true));
    expect(find.text('Your pickup ticket is ready'), findsNothing);
  });

  testWidgets('shows nothing for an already-read notification', (tester) async {
    await _pump(tester, notifications: [_readyNotification(7, isRead: true)], shop: _FakeShop([_order(7, 'QR_ISSUED')]));
    expect(find.text('Your pickup ticket is ready'), findsNothing);
  });
}
