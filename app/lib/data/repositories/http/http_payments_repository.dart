import '../../api_client.dart';
import '../payments_repository.dart';

class HttpPaymentsRepository implements PaymentsRepository {
  HttpPaymentsRepository(this._client);
  final ApiClient _client;

  @override
  Future<DateTime> subscribe({required String phoneNumber}) async {
    try {
      final row = await _client.post('/payments/subscribe/', body: {'phone_number': phoneNumber});
      return DateTime.parse(row['renews_at'] as String);
    } on ApiException catch (e) {
      throw SubscriptionError(e.statusCode == 402 ? 'Payment failed. Check the number and try again.' : 'Subscription failed: ${e.body}');
    }
  }

  @override
  Future<DateTime> redeemSlotBonus() async {
    try {
      final row = await _client.post('/xp/redeem-slot-bonus/');
      return DateTime.parse(row['bonus_offline_slot_until'] as String);
    } on ApiException catch (e) {
      if (e.statusCode == 402) throw InsufficientXPError(apiErrorDetail(e) ?? e.body);
      rethrow;
    }
  }
}
