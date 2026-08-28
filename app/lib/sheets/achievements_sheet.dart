import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/achievement.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_badge.dart';

/// The "All N" list behind Profile's Badges section header (owner decision,
/// 2026-08-28) — every real badge (see data/achievement_definitions.dart),
/// earned or not, with what it actually takes to earn it. [items] is
/// already-resolved (ProfileScreen awaits it first), so this sheet never
/// shows its own loading state.
class AchievementsSheet extends StatelessWidget {
  const AchievementsSheet({super.key, required this.items});

  final List<Achievement> items;

  // Only 4 real badges exist right now (see achievement_definitions.dart) —
  // a plain switch on label is simpler than threading a description field
  // through the repository layer just for this one sheet.
  String _describe(AppLocalizations l10n, String label) {
    switch (label) {
      case 'Spark':
        return l10n.achievementSparkDescription;
      case 'Ember':
        return l10n.achievementEmberDescription;
      case 'Inferno':
        return l10n.achievementInfernoDescription;
      case 'Scholar I':
        return l10n.achievementScholarDescription;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(l10n.allBadgesSheetTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.space4),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Opacity(
                      opacity: items[i].earned ? 1 : 0.45,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.gold200, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Icon(items[i].icon, size: 18, color: AppColors.gold700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                          Text(_describe(l10n, items[i].label), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    SpekoohBadge(
                      text: items[i].earned ? l10n.badgeEarnedLabel : l10n.badgeLockedLabel,
                      tone: items[i].earned ? SpekoohBadgeTone.green : SpekoohBadgeTone.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
