import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/spekooh_button.dart';

/// Shown after a real submission goes through. Was a single checkmark +
/// one paragraph — real, but told the contributor nothing about what a
/// contribution is actually worth. Adapted from a reference
/// rewards-explainer design (owner-provided, 2026-08-30): a decorative
/// badge, a headline, then real facts about Spekooh's actual reward
/// mechanics — no invented points/XP/levels; Spekooh has exactly one
/// currency, bonus credit, plus a real submission-count-based redeem-code
/// tier (see apps.credits.services / apps.payments.services.unlock_paper).
/// Credit is only ever awarded once a submission is verified and published
/// (mark_published) — never claimed as already earned here, since nothing
/// has been credited yet at submission time.
class ContributionRewardScreen extends StatelessWidget {
  const ContributionRewardScreen({super.key, required this.onSubmitAnother});

  final VoidCallback onSubmitAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: AppSpacing.space4),
          child: Column(
            children: [
              _rewardBadge(),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.contributionReceivedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                l10n.contributionRewardsSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.space4),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _rewardRow(
                      icon: LucideIcons.coins,
                      tint: IconChipTint.gold,
                      title: l10n.contributionBenefitCreditTitle,
                      body: l10n.contributionBonusBanner,
                    ),
                    const Divider(height: 1),
                    _rewardRow(
                      icon: LucideIcons.ticket,
                      tint: IconChipTint.green,
                      title: l10n.contributionBenefitDiscountTitle,
                      body: l10n.redeemCodeEarnHint,
                    ),
                    const Divider(height: 1),
                    _rewardRow(
                      icon: LucideIcons.shieldCheck,
                      tint: IconChipTint.blue,
                      title: l10n.contributionBenefitCheckTitle,
                      body: l10n.contributionReceivedBody,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              SizedBox(width: double.infinity, child: SpekoohButton(onPressed: onSubmitAnother, child: Text(l10n.submitAnother))),
            ],
          ),
        ),
      ),
    );
  }

  /// Purely decorative — no real per-submission amount is known yet (credit
  /// is only ever awarded once a submission is verified and published), so
  /// this illustrates the *concept* of a reward rather than a specific
  /// number, the same way the reference design's floating coins/badges
  /// illustrate a concept rather than reporting this exact action's payout.
  Widget _rewardBadge() {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle, boxShadow: AppShadows.button),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.badgeCheck, color: AppColors.white, size: 42),
          ),
          Positioned(top: 2, left: 30, child: _floatingCoin(26)),
          Positioned(top: 16, right: 24, child: _floatingCoin(20)),
          Positioned(bottom: 8, left: 54, child: _floatingCoin(18)),
          Positioned(bottom: 0, right: 50, child: _floatingCoin(22)),
        ],
      ),
    );
  }

  Widget _floatingCoin(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold200, boxShadow: AppShadows.card),
        alignment: Alignment.center,
        child: Icon(LucideIcons.coins, size: size * 0.55, color: AppColors.gold700),
      );

  Widget _rewardRow({required IconData icon, required IconChipTint tint, required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconChip(icon: icon, tint: tint, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
