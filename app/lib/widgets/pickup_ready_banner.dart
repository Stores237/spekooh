import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/repositories/notifications_repository.dart';
import '../data/repositories/shop_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/notification_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "A popup notification should also be seen on the home screen redirecting
/// to the Bookshop order page" (owner request, 2026-09-16). Real domain
/// data, not a fabricated banner: only shows for a genuinely unread
/// PAMPHLET_READY notification (apps.pamphlets.services.place_order),
/// disappearing on its own once Notifications' own markAllRead runs, same
/// as everywhere else in this app that "not built yet"/"nothing to show"
/// renders nothing rather than a placeholder.
///
/// Owner-reported (2026-09-21): it also kept showing after the ticket had
/// been used. The backend now marks the notification read on release, but
/// notifications that were already stale before that fix are still unread
/// -- so the banner also checks the order itself and only shows while it's
/// genuinely still waiting for pickup (QR_ISSUED). If the order can't be
/// confirmed as pending (used, expired, disputed, gone, or the lookup
/// failed), nothing shows: a "ready for pickup" prompt is worse wrong than
/// missing.
class PickupReadyBanner extends StatefulWidget {
  const PickupReadyBanner({super.key, required this.repository, required this.shopRepository, this.onTap});

  final NotificationsRepository repository;
  final ShopRepository shopRepository;
  final ValueChanged<int>? onTap;

  @override
  State<PickupReadyBanner> createState() => _PickupReadyBannerState();
}

class _PickupReadyBannerState extends State<PickupReadyBanner> {
  late final Future<NotificationItem?> _future = _findReady();
  bool _dismissed = false;

  Future<NotificationItem?> _findReady() async {
    final items = await widget.repository.getNotifications();
    final unread = items.where((i) => !i.isRead && i.link.startsWith('qr-vault/')).toList();
    if (unread.isEmpty) return null;
    final orders = await widget.shopRepository.getMyOrders();
    final awaitingPickup = {for (final o in orders) if (o.status == 'QR_ISSUED') o.id};
    for (final item in unread) {
      final orderId = int.tryParse(item.link.substring('qr-vault/'.length));
      if (orderId != null && awaitingPickup.contains(orderId)) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_dismissed) return const SizedBox.shrink();

    return FutureBuilder<NotificationItem?>(
      future: _future,
      builder: (context, snapshot) {
        final ready = snapshot.data;
        if (ready == null) return const SizedBox.shrink();

        final orderId = int.tryParse(ready.link.substring('qr-vault/'.length));
        return GestureDetector(
          onTap: orderId == null ? null : () => widget.onTap?.call(orderId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(LucideIcons.qrCode, size: 20, color: AppColors.green600),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ready.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.green600)),
                      Text(l10n.pickupReadyBannerCta, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.green600)),
                    ],
                  ),
                ),
                GestureDetector(
                  key: const Key('pickupReadyBannerDismiss'),
                  onTap: () => setState(() => _dismissed = true),
                  child: const Icon(LucideIcons.x, size: 16, color: AppColors.green600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
