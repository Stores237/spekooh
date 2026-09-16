import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/shop_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pamphlet.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/qr_vault_lock_gate.dart';
import '../common/circular_back_button.dart';

/// QR Vault (owner request, 2026-09-16): the student's real pickup tickets,
/// gated behind a local PIN (QrVaultLockGate) since a single-use QR code is
/// effectively a bearer credential for collecting a paid order -- anyone
/// who can see the phone screen could otherwise redeem it.
class QrVaultScreen extends StatefulWidget {
  QrVaultScreen({super.key, this.initialOrderId, ShopRepository? repository})
      : repository = repository ?? RepositoryLocator.instance.shop;

  final int? initialOrderId;
  final ShopRepository repository;

  @override
  State<QrVaultScreen> createState() => _QrVaultScreenState();
}

class _QrVaultScreenState extends State<QrVaultScreen> {
  late final Future<List<PamphletOrder>> _ordersFuture = widget.repository.getMyOrders();
  PamphletOrder? _selected;
  bool _appliedInitialSelection = false;

  String _statusLabel(AppLocalizations l10n, String key) {
    switch (key) {
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
        return key;
    }
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _whatsapp(String phone) async {
    await launchUrl(Uri.parse('https://wa.me/$phone'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return QrVaultLockGate(
      child: Scaffold(
        backgroundColor: AppColors.surfaceBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    CircularBackButton(
                      onTap: () {
                        if (_selected != null) {
                          setState(() => _selected = null);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Text(l10n.qrVaultTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Expanded(
                  child: FutureBuilder<List<PamphletOrder>>(
                    future: _ordersFuture,
                    builder: (context, snapshot) {
                      final orders = snapshot.data ?? const <PamphletOrder>[];
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final withTicket = orders.where((o) => o.qrToken != null).toList();

                      if (!_appliedInitialSelection) {
                        _appliedInitialSelection = true;
                        PamphletOrder? initial;
                        if (widget.initialOrderId != null) {
                          for (final order in withTicket) {
                            if (order.id == widget.initialOrderId) initial = order;
                          }
                        } else if (withTicket.length == 1) {
                          initial = withTicket.first;
                        }
                        if (initial != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _selected = initial);
                          });
                        }
                      }

                      if (withTicket.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.qrCode, size: 40, color: AppColors.textTertiary),
                              const SizedBox(height: AppSpacing.space3),
                              Text(l10n.qrVaultEmptyTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(l10n.qrVaultEmptyBody, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }

                      return _selected != null ? _ticketCard(l10n, _selected!) : _list(l10n, withTicket);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(AppLocalizations l10n, List<PamphletOrder> orders) {
    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, i) {
        final order = orders[i];
        return GestureDetector(
          onTap: () => setState(() => _selected = order),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
            child: Row(
              children: [
                const Icon(LucideIcons.qrCode, size: 22, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.pamphletTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                      Text(order.partnerName, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(_statusLabel(l10n, order.status), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(width: 6),
                const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ticketCard(AppLocalizations l10n, PamphletOrder order) {
    final ticketRef = order.qrToken!.substring(0, order.qrToken!.length.clamp(0, 10)).toUpperCase();
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(order.pamphletTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.qrVaultTicketRefLabel, style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                    Text(ticketRef, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_statusLabel(l10n, order.status), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: AppSpacing.space4),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
                child: QrImageView(data: order.qrRedeemUrl ?? order.qrToken!, size: 180),
              ),
            ),
            const SizedBox(height: 6),
            Text(l10n.qrVaultSingleUseNote, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: AppSpacing.space4),
            Container(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: AppSpacing.space4),
            Text(l10n.qrVaultPickupLocationLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(order.partnerName, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            if (order.partnerLocation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order.partnerLocation, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary))),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                if (order.partnerPhone.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _call(order.partnerPhone),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(LucideIcons.phone, size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                if (order.partnerWhatsapp.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _whatsapp(order.partnerWhatsapp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(LucideIcons.messageCircle, size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
