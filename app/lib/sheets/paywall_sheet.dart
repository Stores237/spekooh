import 'package:flutter/material.dart';
import '../data/repositories/payments_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_button.dart';

/// Ported from ui_kits/spekooh-app/PaywallSheet.jsx. Shown via
/// `showModalBottomSheet(isScrollControlled: true, ...)`.
class PaywallSheet extends StatefulWidget {
  PaywallSheet({super.key, PaymentsRepository? repository}) : repository = repository ?? RepositoryLocator.instance.payments;

  final PaymentsRepository repository;

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  List<(IconData, String)> _benefits(AppLocalizations l10n) => [
        (Icons.visibility_outlined, l10n.paywallBenefitViews),
        (Icons.block, l10n.paywallBenefitAds),
        (Icons.notifications_none, l10n.paywallBenefitAlerts),
      ];

  final _phoneController = TextEditingController();
  bool _subscribing = false;
  String? _error;
  DateTime? _renewsAt;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = l10n.paywallEnterPhoneError);
      return;
    }
    setState(() {
      _subscribing = true;
      _error = null;
    });
    try {
      final renewsAt = await widget.repository.subscribe(phoneNumber: phone);
      if (mounted) setState(() => _renewsAt = renewsAt);
    } on SubscriptionError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = l10n.paywallSubscriptionFailed('$e'));
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final benefits = _benefits(l10n);
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Icon(_renewsAt != null ? Icons.check : Icons.star, color: AppColors.white, size: 26),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(_renewsAt != null ? l10n.paywallYoureProTitle : l10n.paywallGetProTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            if (_renewsAt != null)
              Text(
                l10n.paywallRenewsOn('${_renewsAt!.year}-${_renewsAt!.month.toString().padLeft(2, '0')}-${_renewsAt!.day.toString().padLeft(2, '0')}'),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
              )
            else
              Text(
                l10n.paywallDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
              ),
            const SizedBox(height: AppSpacing.space4),
            if (_renewsAt == null) ...[
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (var i = 0; i < benefits.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green100),
                              alignment: Alignment.center,
                              child: Icon(benefits[i].$1, size: 14, color: AppColors.green600),
                            ),
                            const SizedBox(width: 10),
                            Text(benefits[i].$2, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: Border.all(color: AppColors.blue400, width: 1.5), borderRadius: BorderRadius.circular(18)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.spekoohProCaps, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4)),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                        children: const [TextSpan(text: '500 '), TextSpan(text: 'FCFA/mo', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600))],
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
                const SizedBox(height: AppSpacing.space2),
                Text(_error!, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.red500)),
              ],
              const SizedBox(height: AppSpacing.space4),
              SizedBox(
                width: double.infinity,
                child: SpekoohButton(
                  onPressed: _subscribing ? null : _subscribe,
                  child: _subscribing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.payButton),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                l10n.paywallDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textTertiary),
              ),
            ] else
              SizedBox(width: double.infinity, child: SpekoohButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.doneLabel))),
          ],
        ),
      ),
    );
  }
}
