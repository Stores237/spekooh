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
}
