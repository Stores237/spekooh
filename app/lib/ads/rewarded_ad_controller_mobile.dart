import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'rewarded_ad_controller.dart';

RewardedAdController createRewardedAdController() => AdMobRewardedAdController();

class AdMobRewardedAdController implements RewardedAdController {
  @override
  Future<bool> showAd() async {
    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              if (!completer.isCompleted) completer.complete(true);
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }
}
