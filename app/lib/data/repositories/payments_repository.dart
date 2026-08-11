class SubscriptionError implements Exception {
  SubscriptionError(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class PaymentsRepository {
  /// Subscribes to Spekooh Pro via the real MockPaymentProvider-backed
  /// endpoint. Returns the real renewal date on success; throws
  /// [SubscriptionError] if the charge fails.
  Future<DateTime> subscribe({required String phoneNumber});
}

class MockPaymentsRepository implements PaymentsRepository {
  @override
  Future<DateTime> subscribe({required String phoneNumber}) async =>
      DateTime.now().add(const Duration(days: 30));
}
