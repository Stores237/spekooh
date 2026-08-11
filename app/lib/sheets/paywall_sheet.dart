import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_button.dart';

/// Ported from ui_kits/spekooh-app/PaywallSheet.jsx. Shown via
/// `showModalBottomSheet(isScrollControlled: true, ...)`.
class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key});

  static const _benefits = [
    (Icons.visibility_outlined, 'Unlimited question paper views'),
    (Icons.block, 'Zero ads while you study'),
    (Icons.notifications_none, 'Instructor status alerts'),
  ];

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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Icon(Icons.star, color: AppColors.white, size: 26),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text('Get Spekooh Pro', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Unlimited question-paper views and an ad-free app. Marking guides are always unlocked separately.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space4),
          Container(
            decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var i = 0; i < _benefits.length; i++) ...[
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
                          child: Icon(_benefits[i].$1, size: 14, color: AppColors.green600),
                        ),
                        const SizedBox(width: 10),
                        Text(_benefits[i].$2, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary)),
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
                const Text('SPEKOOH PRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4)),
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
                    decoration: InputDecoration(hintText: '670 12 34 56', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          SizedBox(width: double.infinity, child: SpekoohButton(onPressed: () {}, child: const Text('Pay 500 FCFA'))),
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Official Spekooh merchant · we never ask for your PIN · receipt + SMS within 2 min',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
      ),
    );
  }
}
