import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// Horizontal scrolling row of pill filter tabs — category filters, year
/// filters. Active = solid ink fill + white text; inactive = white card +
/// soft shadow + gray text. Ported from
/// components/navigation/SegmentedTabs.jsx.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.options, required this.active, required this.onChanged});

  final List<String> options;
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isActive = i == active;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.ink900 : AppColors.surfaceCard,
                borderRadius: AppRadii.radiusPill,
                boxShadow: isActive ? null : AppShadows.card,
              ),
              alignment: Alignment.center,
              child: Text(
                options[i],
                style: TextStyle(
                  fontFamily: plusJakartaSansFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
