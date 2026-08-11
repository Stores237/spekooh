class SpekoohUser {
  const SpekoohUser({
    required this.name,
    required this.joinDate,
    required this.submissionsCount,
    required this.quizzesCount,
    required this.creditBalance,
    required this.redeemCode,
    required this.redeemCodeSubtitle,
  });

  final String name;
  final String joinDate;
  final int submissionsCount;
  final int quizzesCount;
  final int creditBalance;
  final String redeemCode;
  final String redeemCodeSubtitle;
}
