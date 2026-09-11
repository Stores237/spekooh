class SubscriptionError implements Exception {
  SubscriptionError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// [PaymentsRepository.redeemSlotBonus] — the account doesn't have enough
/// XP yet. Carries the real backend detail message (e.g. "You need 250 XP
/// to redeem this. You have 40.") so the UI can show it as-is.
class InsufficientXPError implements Exception {
  InsufficientXPError(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class PaymentsRepository {
  /// Subscribes to Spekooh Pro via the real MockPaymentProvider-backed
  /// endpoint. Returns the real renewal date on success; throws
  /// [SubscriptionError] if the charge fails.
  Future<DateTime> subscribe({required String phoneNumber});

  /// Real XP economy (owner request, 2026-09-11) — spends 250 XP for a
  /// real +1 offline download slot, active for 3 days from now (see
  /// backend apps.xp.services.redeem_slot_bonus, the actual source of
  /// truth for the cost/duration). Returns the new bonus expiry. Throws
  /// [InsufficientXPError] if the account doesn't have enough XP yet.
  Future<DateTime> redeemSlotBonus();
}

class MockPaymentsRepository implements PaymentsRepository {
  @override
  Future<DateTime> subscribe({required String phoneNumber}) async =>
      DateTime.now().add(const Duration(days: 30));

  /// Null by default — real usage starts able to redeem (mirrors a fresh
  /// account genuinely having earned enough XP already in a test). Set to
  /// an [InsufficientXPError] to exercise the real "not enough yet" path.
  Object? mockRedeemError;

  @override
  Future<DateTime> redeemSlotBonus() async {
    final error = mockRedeemError;
    if (error != null) throw error;
    return DateTime.now().add(const Duration(days: 3));
  }
}
