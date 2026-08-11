import 'dart:math';

import '../../models/pamphlet.dart';
import '../mock/mock_pamphlets.dart';

class PamphletOrderResult {
  const PamphletOrderResult({required this.qrToken, required this.status});
  final String qrToken;
  final String status;
}

abstract class ShopRepository {
  Future<List<Pamphlet>> getPamphlets();
  Future<Pamphlet> getFeaturedPamphlet();
  Future<PamphletOrderResult> placeOrder({
    required int pamphletId,
    required bool isDelivery,
    required String phoneNumber,
  });
}

class MockShopRepository implements ShopRepository {
  @override
  Future<List<Pamphlet>> getPamphlets() => Future.value(mockPamphlets);

  @override
  Future<Pamphlet> getFeaturedPamphlet() => Future.value(mockFeaturedPamphlet);

  @override
  Future<PamphletOrderResult> placeOrder({
    required int pamphletId,
    required bool isDelivery,
    required String phoneNumber,
  }) async {
    final token = 'mock-qr-${Random().nextInt(999999)}';
    return PamphletOrderResult(qrToken: token, status: 'QR_ISSUED');
  }
}
