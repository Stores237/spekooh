import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_theme.dart';

class SpekoohStat {
  const SpekoohStat({this.icon, required this.value, required this.label});
  final Widget? icon;
  final String value;
  final String label;
}

/// Divided N-up stat strip on quiz-detail screens: "15 questions · 8 min
/// suggested · 5564 played". Ported from
/// components/data-display/StatRow.jsx.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.stats});

  final List<SpekoohStat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadii.radiusLg,
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++)
            Expanded(
              child: Container(
                decoration: i > 0
                    ? const BoxDecoration(
                        border: Border(left: BorderSide(color: AppColors.borderSubtle)),
                      )
                    : null,
                child: Column(
                  children: [
                    if (stats[i].icon != null) ...[
                      IconTheme.merge(
                        data: const IconThemeData(color: AppColors.textSecondary, size: 16),
                        child: stats[i].icon!,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      stats[i].value,
                      style: TextStyle(
                        fontFamily: plusJakartaSansFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats[i].label,
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
      ),
    );
  }
}
