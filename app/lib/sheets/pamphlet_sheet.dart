import 'package:flutter/material.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/pamphlet.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ported from ui_kits/spekooh-app/PamphletSheet.jsx. Two internal states:
/// summary+pay, then a QR pickup ticket. Shown via
/// `showModalBottomSheet(isScrollControlled: true, ...)`.
class PamphletSheet extends StatefulWidget {
  PamphletSheet({super.key, required this.pamphlet, ShopRepository? repository})
      : repository = repository ?? RepositoryLocator.instance.shop;

  final Pamphlet pamphlet;
  final ShopRepository repository;

  @override
  State<PamphletSheet> createState() => _PamphletSheetState();
}

class _PamphletSheetState extends State<PamphletSheet> {
  bool _paid = false;
  bool _isPaying = false;
  String? _error;
  String? _qrToken;
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isPaying = true;
      _error = null;
    });
    try {
      final result = await widget.repository.placeOrder(
        pamphletId: widget.pamphlet.id,
        isDelivery: false,
        phoneNumber: _phoneController.text.trim().isEmpty ? '000000000' : _phoneController.text.trim(),
      );
      setState(() {
        _qrToken = result.qrToken;
        _paid = true;
      });
    } catch (_) {
      if (mounted) setState(() => _error = l10n.paymentFailedGeneric);
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      // Grows with the keyboard (see AuthSheet's own comment on this same
      // fix) so it shifts the field above the keyboard instead of letting
      // the keyboard cover it.
      padding: EdgeInsets.fromLTRB(22, 10, 22, 26 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: AppShadows.sheet,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.space4),
            if (!_paid) ..._summary(l10n) else ..._ticket(l10n),
          ],
        ),
      ),
    );
  }

  List<Widget> _summary(AppLocalizations l10n) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(gradient: AppGradients.goldDeep, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pamphlet.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(l10n.pamphletSoldBy(widget.pamphlet.partner), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space4),
      Text(
        l10n.escrowExplanation,
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary, height: 1.5),
      ),
      const SizedBox(height: AppSpacing.space4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.gold400, width: 1.5), borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.pickupInStoreLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4)),
            RichText(
              text: TextSpan(
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '${widget.pamphlet.priceFcfa} '),
                  const TextSpan(text: 'FCFA', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(l10n.momoOrangeLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4)),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text('+237', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '670 12 34 56', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.space3),
        Text(_error!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
      ],
      const SizedBox(height: AppSpacing.space4),
      SizedBox(
        width: double.infinity,
        child: SpekoohButton(
          onPressed: _isPaying ? null : _pay,
          child: Text(_isPaying ? l10n.processingLabel : l10n.payAndReserve(widget.pamphlet.priceFcfa)),
        ),
      ),
      const SizedBox(height: AppSpacing.space3),
      Text(
        l10n.escrowFooterNote,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textTertiary),
      ),
    ];
  }

  List<Widget> _ticket(AppLocalizations l10n) {
    return [
      Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: const Icon(LucideIcons.qrCode, color: AppColors.white, size: 96),
      ),
      const SizedBox(height: AppSpacing.space3),
      Text(l10n.pickupTicketReady, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text(
        l10n.showQrAtPartner(widget.pamphlet.partner),
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
      ),
      if (_qrToken != null) ...[
        const SizedBox(height: 6),
        Text(l10n.ticketRefLabel(_qrToken!.substring(0, _qrToken!.length.clamp(0, 12))), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ],
      const SizedBox(height: AppSpacing.space4),
      SpekoohButton(
        variant: SpekoohButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.doneLabel),
      ),
    ];
  }
}
