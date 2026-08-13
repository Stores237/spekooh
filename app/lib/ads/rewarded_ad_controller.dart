import 'rewarded_ad_controller_stub.dart' if (dart.library.io) 'rewarded_ad_controller_mobile.dart' as platform;

/// Wraps the AdMob rewarded-video callback API behind a simple
/// `Future<bool>` so [PaperDetailScreen] doesn't depend on the SDK's
/// load/show/callback lifecycle directly, and so widget tests can inject a
/// fake instead of touching the real SDK (no platform channel under
/// `flutter test`, and google_mobile_ads doesn't exist at all on web).
abstract class RewardedAdController {
  static RewardedAdController instance = platform.createRewardedAdController();

  static void debugSetInstance(RewardedAdController controller) => instance = controller;

  /// Loads and shows a rewarded ad. Returns whether the user actually
  /// earned the reward (false on early close, load failure, or — on web,
  /// where google_mobile_ads isn't supported — always).
  Future<bool> showAd();
}
