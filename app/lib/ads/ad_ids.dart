import 'package:flutter/foundation.dart';

/// Rewarded-video ad unit ID for the paper-view unlock mechanic
/// (TODOS.md P0 #2 / spec §5.3). In debug builds this returns Google's
/// public test unit — requesting the real one from a developer device
/// counts as invalid traffic under AdMob policy and risks the account.
///
/// Uses [defaultTargetPlatform] rather than dart:io's Platform so this
/// file stays web-compilable (google_mobile_ads itself is mobile-only —
/// callers must guard usage with kIsWeb — but merely importing this
/// constant must not break `flutter build web`).
String get rewardedAdUnitId {
  if (kDebugMode) {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';
  }
  return 'ca-app-pub-6272769995522353/4880625266';
}
