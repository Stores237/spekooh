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
    this.avatarUrl,
    this.email = '',
    this.phoneNumber = '',
  });

  final String name;
  final String joinDate;

  /// Empty means genuinely not set (a guest, or a registered user who
  /// skipped it) — never a fabricated placeholder. Pre-fills the real Edit
  /// profile sheet; see ProfileRepository.updateProfile.
  final String email;
  final String phoneNumber;
  final int submissionsCount;
  final int quizzesCount;
  final int creditBalance;
  final String redeemCode;
  final String redeemCodeSubtitle;
  final int trialDaysRemaining;
  final bool firstUnlockFreeEligible;

  /// Null means genuinely no photo set — the profile screen falls back to
  /// an initial-letter avatar, never a fabricated placeholder image.
  final String? avatarUrl;

  /// Shareable code a new signup can enter at registration — the referrer
  /// earns a real credit bonus once the referred user completes their first
  /// paper unlock (see apps.credits.services.award_referral_bonus).
  final String referralCode;
}
