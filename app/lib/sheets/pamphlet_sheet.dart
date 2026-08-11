import 'package:flutter/material.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repository_locator.dart';
import '../models/pamphlet.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_button.dart';

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
      setState(() => _error = 'Payment failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
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
            if (!_paid) ..._summary() else ..._ticket(),
          ],
        ),
      ),
    );
  }

  List<Widget> _summary() {
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
                Text('Sold by ${widget.pamphlet.partner}', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space4),
      Text(
        'Spekooh holds your payment in escrow. You\'ll get a one-time QR ticket to collect it at the bookshop — payment only releases to the partner once they scan it.',
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary, height: 1.5),
      ),
      const SizedBox(height: AppSpacing.space4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.gold400, width: 1.5), borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PICKUP · IN-STORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4)),
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
        child: Text('MTN MOMO OR ORANGE MONEY NUMBER', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4)),
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
          child: Text(_isPaying ? 'Processing…' : 'Pay & reserve — ${widget.pamphlet.priceFcfa} FCFA'),
        ),
      ),
      const SizedBox(height: AppSpacing.space3),
      Text(
        'Held in escrow · released to partner only after pickup is confirmed · 5% platform commission',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textTertiary),
      ),
    ];
  }

  List<Widget> _ticket() {
    return [
      Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: const Icon(Icons.qr_code_2, color: AppColors.white, size: 96),
      ),
      const SizedBox(height: AppSpacing.space3),
      Text('Pickup ticket ready', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text(
        'Show this QR at ${widget.pamphlet.partner}. Single-use — expires in 30 days. Payment releases to the partner once they scan it.',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
      ),
      if (_qrToken != null) ...[
        const SizedBox(height: 6),
        Text('Ticket ref: ${_qrToken!.substring(0, _qrToken!.length.clamp(0, 12))}…', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ],
      const SizedBox(height: AppSpacing.space4),
      SpekoohButton(
        variant: SpekoohButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Done'),
      ),
    ];
  }
}
