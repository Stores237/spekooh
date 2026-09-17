import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/recent_shop_items_visibility.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/pamphlet.dart';
import 'package:spekooh/widgets/recent_shop_items_card.dart';

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
  Future<PamphletOrderResult> placeOrder({
    required int pamphletId,
    required bool isDelivery,
    required String phoneNumber,
    int quantity = 1,
    String deliveryAddress = '',
  }) => throw UnimplementedError();
}

final _oneOrder = [
  PamphletOrder(
    id: 1,
    pamphletTitle: 'Probatoire Philosophy Pamphlet',
    status: 'QR_ISSUED',
    amountPaid: 7500,
    createdAt: DateTime(2026, 9, 15),
  ),
];

void main() {
  tearDown(() {
    RecentShopItemsVisibility.debugSetInstance(
      RecentShopItemsVisibility(storage: InMemoryTokenStorage()),
    );
  });

  testWidgets('shows the real order and the SPONSORED label', (tester) async {
    RecentShopItemsVisibility.debugSetInstance(
      RecentShopItemsVisibility(storage: InMemoryTokenStorage()),
    );
    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: RecentShopItemsCard(repository: _FakeShopRepository(_oneOrder)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('SPONSORED'), findsOneWidget);
    expect(find.text('Recent shop items'), findsOneWidget);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget);
    expect(find.text('Ready for pickup'), findsOneWidget);
  });

  testWidgets('renders nothing when there are no recent orders', (
    tester,
  ) async {
    RecentShopItemsVisibility.debugSetInstance(
      RecentShopItemsVisibility(storage: InMemoryTokenStorage()),
    );
    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: RecentShopItemsCard(repository: _FakeShopRepository(const [])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Recent shop items'), findsNothing);
  });

  testWidgets(
    'dismissing hides it immediately and persists across a fresh instance',
    (tester) async {
      final storage = InMemoryTokenStorage();
      RecentShopItemsVisibility.debugSetInstance(
        RecentShopItemsVisibility(storage: storage),
      );
      await tester.pumpWidget(
        l10nTestApp(
          Scaffold(
            body: RecentShopItemsCard(
              repository: _FakeShopRepository(_oneOrder),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Recent shop items'), findsOneWidget);

      await tester.tap(find.byKey(const Key('recentShopItemsDismissButton')));
      await tester.pump();

      expect(find.text('Recent shop items'), findsNothing);

      // A real, separate check against the same storage sees it too — not
      // just in-memory widget state that would reappear on the next launch.
      expect(
        await RecentShopItemsVisibility(storage: storage).isDismissed(),
        isTrue,
      );
    },
  );

  testWidgets('never flashes the card before a real dismissed check resolves', (
    tester,
  ) async {
    final storage = InMemoryTokenStorage();
    await storage.write('recent_shop_items_dismissed', 'true');
    RecentShopItemsVisibility.debugSetInstance(
      RecentShopItemsVisibility(storage: storage),
    );
    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: RecentShopItemsCard(repository: _FakeShopRepository(_oneOrder)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Recent shop items'), findsNothing);
  });

  testWidgets('tapping an order or See all triggers onSeeAll', (tester) async {
    RecentShopItemsVisibility.debugSetInstance(
      RecentShopItemsVisibility(storage: InMemoryTokenStorage()),
    );
    var seeAllTapped = false;
    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: RecentShopItemsCard(
            repository: _FakeShopRepository(_oneOrder),
            onSeeAll: () => seeAllTapped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('See all'));
    expect(seeAllTapped, isTrue);
  });
}
