import 'package:flutter/foundation.dart';

import 'token_storage.dart';

/// Whether the "Advertise on Kawlo" house ad on Home is still shown —
/// owner request, 2026-09-11: "make it removable if not needed by user".
/// Reuses TokenStorage (already wired to real flutter_secure_storage, with
/// a real InMemoryTokenStorage test double) rather than adding a new
/// dependency just for one boolean flag.
class HouseAdVisibility {
  HouseAdVisibility({TokenStorage? storage}) : _storage = storage ?? const SecureTokenStorage();

  static HouseAdVisibility instance = HouseAdVisibility();

  @visibleForTesting
  static void debugSetInstance(HouseAdVisibility visibility) => instance = visibility;

  static const _dismissedKey = 'house_ad_dismissed';

  final TokenStorage _storage;

  Future<bool> isDismissed() async => (await _storage.read(_dismissedKey)) == 'true';

  Future<void> dismiss() => _storage.write(_dismissedKey, 'true');
}
