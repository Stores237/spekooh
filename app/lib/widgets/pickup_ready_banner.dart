import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/repositories/notifications_repository.dart';
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
class PickupReadyBanner extends StatefulWidget {
  const PickupReadyBanner({super.key, required this.repository, this.onTap});

  final NotificationsRepository repository;
  final ValueChanged<int>? onTap;

  @override
  State<PickupReadyBanner> createState() => _PickupReadyBannerState();
}

class _PickupReadyBannerState extends State<PickupReadyBanner> {
  late final Future<List<NotificationItem>> _future = widget.repository.getNotifications();
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_dismissed) return const SizedBox.shrink();

    return FutureBuilder<List<NotificationItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <NotificationItem>[];
        NotificationItem? ready;
        for (final item in items) {
          if (!item.isRead && item.link.startsWith('qr-vault/')) {
            ready = item;
            break;
          }
        }
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
