/// Which features are really switched on, as reported by the server (GET
/// /status/features/). The app shows a "not fully functional yet" notice next
/// to anything that looks live but is not, and the notice goes away by itself
/// once the server says the feature is live: no app release needed.
class FeatureStatus {
  const FeatureStatus({required this.paymentsLive});

  /// When the server can't be asked, assume the cautious answer: not live.
  /// A missing notice on a fake payment is worse than a notice that lingers
  /// for someone who happens to be offline.
  const FeatureStatus.unknown() : paymentsLive = false;

  /// False while payments are simulated: every charge is approved and no
  /// money moves.
  final bool paymentsLive;
}
