import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/pamphlet.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/phone_number_field.dart';
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
  String? _deliveryAddressError;
  String? _qrToken;
  final _phoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  int _quantity = 1;
  bool _isDelivery = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  int get _totalFcfa => widget.pamphlet.priceFcfaValue * _quantity + (_isDelivery ? widget.pamphlet.deliveryFeeFcfa : 0);

  static String _formatWithCommas(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Future<void> _viewOnMap() async {
    final query = Uri.encodeComponent(widget.pamphlet.partnerLocation);
    await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'), mode: LaunchMode.externalApplication);
  }

  Future<void> _pay() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isDelivery && _deliveryAddressController.text.trim().isEmpty) {
      setState(() => _deliveryAddressError = l10n.pamphletDeliveryAddressRequired);
      return;
    }
    setState(() {
      _isPaying = true;
      _error = null;
      _deliveryAddressError = null;
    });
    try {
      final result = await widget.repository.placeOrder(
        pamphletId: widget.pamphlet.id,
        isDelivery: _isDelivery,
        phoneNumber: _phoneController.text.trim().isEmpty ? '000000000' : _phoneController.text.trim(),
        quantity: _quantity,
        deliveryAddress: _isDelivery ? _deliveryAddressController.text.trim() : '',
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
      // Number of copies (owner reference, 2026-09-17): every other order
      // this sheet has ever placed was implicitly qty=1 -- the total below
      // and the real amount charged (place_order's quantity param) both
      // now scale with this.
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.pamphletQuantityLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Row(
            children: [
              _stepperButton(icon: LucideIcons.minus, onTap: _quantity > 1 ? () => setState(() => _quantity--) : null),
              SizedBox(width: 32, child: Text('$_quantity', textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary))),
              _stepperButton(icon: LucideIcons.plus, onTap: () => setState(() => _quantity++)),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space4),
      // Pickup-vs-delivery (real pre-existing gap, 2026-09-17): the escrow
      // model already had is_delivery/delivery_fee_fcfa, but this sheet
      // never actually offered delivery at all -- only shown when the
      // pamphlet's own partner has opted into it.
      if (widget.pamphlet.deliveryAvailable) ...[
        Row(
          children: [
            Expanded(child: _optionChip(label: l10n.pamphletPickupOptionLabel, selected: !_isDelivery, onTap: () => setState(() => _isDelivery = false))),
            const SizedBox(width: 8),
            Expanded(child: _optionChip(label: l10n.pamphletDeliveryOptionLabel, selected: _isDelivery, onTap: () => setState(() => _isDelivery = true))),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      if (_isDelivery) ...[
        AuthTextField(controller: _deliveryAddressController, hint: l10n.pamphletDeliveryAddressHint),
        if (_deliveryAddressError != null) ...[
          const SizedBox(height: 6),
          Text(_deliveryAddressError!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
        ],
        const SizedBox(height: AppSpacing.space3),
      ] else if (widget.pamphlet.partnerLocation.isNotEmpty) ...[
        GestureDetector(
          onTap: _viewOnMap,
          child: Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 14, color: AppColors.gold700),
              const SizedBox(width: 4),
              Expanded(child: Text(widget.pamphlet.partnerLocation, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary))),
              Text(l10n.pamphletViewOnMap, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold700)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.gold400, width: 1.5), borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_isDelivery ? l10n.pamphletDeliveryOptionLabel.toUpperCase() : l10n.pickupInStoreLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4)),
            RichText(
              text: TextSpan(
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '${_formatWithCommas(_totalFcfa)} '),
                  const TextSpan(text: 'FCFA', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      PhoneNumberField(controller: _phoneController, error: _error),
      const SizedBox(height: AppSpacing.space4),
      SizedBox(
        width: double.infinity,
        child: SpekoohButton(
          onPressed: _isPaying ? null : _pay,
          child: Text(_isPaying ? l10n.processingLabel : l10n.payAndReserve(_formatWithCommas(_totalFcfa))),
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

  Widget _stepperButton({required IconData icon, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(8),
          color: onTap == null ? AppColors.surfaceSunken : AppColors.white,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: onTap == null ? AppColors.textTertiary : AppColors.textPrimary),
      ),
    );
  }

  Widget _optionChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold50 : AppColors.surfaceSunken,
          border: Border.all(color: selected ? AppColors.gold400 : AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: selected ? AppColors.gold700 : AppColors.textSecondary),
        ),
      ),
    );
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
