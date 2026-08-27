import '../../../models/pamphlet.dart';
import '../../api_client.dart';
import '../shop_repository.dart';

class HttpShopRepository implements ShopRepository {
  HttpShopRepository(this._client);
  final ApiClient _client;

  Pamphlet _fromJson(Map<String, dynamic> row) {
    final priceValue = row['price_fcfa'] as int;
    return Pamphlet(
      id: row['id'] as int,
      title: row['title'] as String,
      partner: row['partner_name'] as String? ?? '',
      priceFcfa: _formatWithCommas(priceValue),
      priceFcfaValue: priceValue,
      description: row['description'] as String? ?? '',
      deliveryAvailable: row['delivery_available'] as bool? ?? false,
      deliveryFeeFcfa: row['delivery_fee_fcfa'] as int? ?? 0,
      subjectTitle: row['subject_title'] as String? ?? '',
      academicLevel: row['academic_level'] as String? ?? '',
    );
  }

  static String _formatWithCommas(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Future<List<Pamphlet>> getPamphlets() async {
    final rows = await _client.get('/pamphlets/catalog/') as List;
    return rows.map((row) => _fromJson(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<Pamphlet> getFeaturedPamphlet() async {
    final row = await _client.get('/pamphlets/catalog/featured/');
    return _fromJson(row as Map<String, dynamic>);
  }

  @override
  Future<PamphletOrderResult> placeOrder({
    required int pamphletId,
    required bool isDelivery,
    required String phoneNumber,
  }) async {
    final row = await _client.post('/pamphlets/orders/place/', body: {
      'pamphlet': pamphletId,
      'is_delivery': isDelivery,
      'phone_number': phoneNumber,
    });
    return PamphletOrderResult(qrToken: row['qr_token'] as String, status: row['status'] as String);
  }
}
