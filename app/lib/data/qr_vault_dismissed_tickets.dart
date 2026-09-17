import 'package:flutter/foundation.dart';

import 'token_storage.dart';

/// Owner request (2026-09-17): once a pamphlet order is picked up
/// (RELEASED), the user should be able to clear its ticket out of the QR
/// Vault list. This never touches the real order record on the backend --
/// PamphletOrder is the actual escrow ledger, an audit trail that stays
/// intact regardless. "Deleting a ticket" only means hiding it from this
/// device's Vault view, the same on-device-only, no-server-round-trip model
/// QrVaultPin already uses for the PIN itself.
class QrVaultDismissedTickets {
  QrVaultDismissedTickets({TokenStorage? storage}) : _storage = storage ?? const SecureTokenStorage();

  static QrVaultDismissedTickets instance = QrVaultDismissedTickets();

  @visibleForTesting
  static void debugSetInstance(QrVaultDismissedTickets tickets) => instance = tickets;

  static const _key = 'qr_vault_dismissed_order_ids';

  final TokenStorage _storage;

  Future<Set<int>> dismissedIds() async {
    final raw = await _storage.read(_key);
    if (raw == null || raw.isEmpty) return <int>{};
    return raw.split(',').map(int.parse).toSet();
  }

  Future<void> dismiss(int orderId) async {
    final ids = await dismissedIds();
    ids.add(orderId);
    await _storage.write(_key, ids.join(','));
  }
}
