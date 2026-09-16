import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/recent_shop_items_visibility.dart';
import '../data/repositories/shop_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/pamphlet.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import 'icon_chip.dart';

/// The student's own recent pamphlet orders on Home — owner request,
/// 2026-09-16. Same dismiss-and-remember shape as HouseAdCard
/// (RecentShopItemsVisibility mirrors HouseAdVisibility exactly), labeled
/// with the same "SPONSORED"-style badge used there, since this is Spekooh's
/// own shop promoting itself back to a student who's already used it, not a
/// third-party ad.
class RecentShopItemsCard extends StatefulWidget {
  const RecentShopItemsCard({
    super.key,
    required this.repository,
    this.onSeeAll,
    this.onOpenOrder,
  });

  final ShopRepository repository;
  final VoidCallback? onSeeAll;

  /// QR Vault (2026-09-16): tapping a specific order opens its pickup
  /// ticket directly, rather than only the generic "See all" shop link.
  final ValueChanged<int>? onOpenOrder;

  @override
  State<RecentShopItemsCard> createState() => _RecentShopItemsCardState();
}

class _RecentShopItemsCardState extends State<RecentShopItemsCard> {
  late final Future<bool> _dismissedFuture = RecentShopItemsVisibility.instance
      .isDismissed();
  late final Future<List<PamphletOrder>> _ordersFuture = widget.repository
      .getMyOrders();
  bool? _dismissedOverride;

  Future<void> _dismiss() async {
    await RecentShopItemsVisibility.instance.dismiss();
    if (mounted) setState(() => _dismissedOverride = true);
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'PAID_HELD':
        return l10n.recentShopItemsStatusPaidHeld;
      case 'QR_ISSUED':
        return l10n.recentShopItemsStatusQrIssued;
      case 'RELEASED':
        return l10n.recentShopItemsStatusReleased;
      case 'EXPIRED':
        return l10n.recentShopItemsStatusExpired;
      case 'DISPUTED':
        return l10n.recentShopItemsStatusDisputed;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: _dismissedFuture,
      builder: (context, dismissedSnapshot) {
        // No flash of a card that's about to disappear: nothing renders
        // until the real dismissed-state check resolves, and nothing
        // renders at all once dismissed (this run's tap or a past one).
        if (dismissedSnapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (_dismissedOverride ?? dismissedSnapshot.data ?? false) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<PamphletOrder>>(
          future: _ordersFuture,
          builder: (context, ordersSnapshot) {
            final orders = ordersSnapshot.data ?? const <PamphletOrder>[];
            // No orders yet -- nothing recent to show, and no point
            // occupying Home with an empty "recent" section.
            if (ordersSnapshot.connectionState == ConnectionState.done &&
                orders.isEmpty) {
              return const SizedBox.shrink();
            }
            if (ordersSnapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSunken,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.recentShopItemsSponsoredLabel,
                          style: TextStyle(
                            fontFamily: plusJakartaSansFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: const Key('recentShopItemsDismissButton'),
                        onTap: _dismiss,
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentShopItemsTitle,
                        style: TextStyle(
                          fontFamily: plusJakartaSansFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.onSeeAll != null)
                        GestureDetector(
                          onTap: widget.onSeeAll,
                          child: Text(
                            l10n.recentShopItemsSeeAll,
                            style: TextStyle(
                              fontFamily: plusJakartaSansFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final order in orders.take(3)) ...[
                    GestureDetector(
                      onTap: widget.onOpenOrder != null ? () => widget.onOpenOrder!(order.id) : widget.onSeeAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const IconChip(
                              icon: LucideIcons.bookOpen,
                              tint: IconChipTint.amber,
                              size: 36,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order.pamphletTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: plusJakartaSansFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _statusLabel(l10n, order.status),
                              style: TextStyle(
                                fontFamily: plusJakartaSansFamily,
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
