import 'package:flutter/foundation.dart';

import 'token_storage.dart';

/// Whether the "Recent shop items" card on Home is still shown — same
/// dismiss-and-remember shape as HouseAdVisibility (owner request,
/// 2026-09-16), reusing TokenStorage rather than a new dependency for one
/// boolean flag.
class RecentShopItemsVisibility {
  RecentShopItemsVisibility({TokenStorage? storage})
    : _storage = storage ?? const SecureTokenStorage();

  static RecentShopItemsVisibility instance = RecentShopItemsVisibility();

  @visibleForTesting
  static void debugSetInstance(RecentShopItemsVisibility visibility) =>
      instance = visibility;

  static const _dismissedKey = 'recent_shop_items_dismissed';

  final TokenStorage _storage;

  Future<bool> isDismissed() async =>
      (await _storage.read(_dismissedKey)) == 'true';

  Future<void> dismiss() => _storage.write(_dismissedKey, 'true');
}
