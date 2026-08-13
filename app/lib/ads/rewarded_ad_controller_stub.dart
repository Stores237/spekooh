import 'rewarded_ad_controller.dart';

/// Web build of [RewardedAdController]: google_mobile_ads has no web
/// support, so there's no ad to show here. Callers gate the "Watch ad"
/// affordance itself behind `kIsWeb` — this stub exists so the conditional
/// import in rewarded_ad_controller.dart still resolves to something
/// web-compilable if that gate is ever missed.
RewardedAdController createRewardedAdController() => _UnsupportedRewardedAdController();

class _UnsupportedRewardedAdController implements RewardedAdController {
  @override
  Future<bool> showAd() async => false;
}
