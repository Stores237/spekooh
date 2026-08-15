class SpekoohUser {
  const SpekoohUser({
    required this.name,
    required this.joinDate,
    required this.submissionsCount,
    required this.quizzesCount,
    required this.creditBalance,
    required this.redeemCode,
    required this.redeemCodeSubtitle,
    this.trialDaysRemaining = 0,
    this.firstUnlockFreeEligible = false,
    this.referralCode = '',
  });

  final String name;
  final String joinDate;
  final int submissionsCount;
  final int quizzesCount;
  final int creditBalance;
  final String redeemCode;
  final String redeemCodeSubtitle;
  final int trialDaysRemaining;
  final bool firstUnlockFreeEligible;

  /// Shareable code a new signup can enter at registration — the referrer
  /// earns a real credit bonus once the referred user completes their first
  /// paper unlock (see apps.credits.services.award_referral_bonus).
  final String referralCode;
}
