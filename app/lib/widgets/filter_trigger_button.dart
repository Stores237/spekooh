import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_theme.dart';

/// Compact pill button that sits beside a [SearchInput] and opens a bottom
/// sheet with the screen's actual filters. Replaces two permanent, always-
/// expanded chip rows (NotesScreen/ShopScreen used to show "Subject" and
/// "Level" full-width every time, pushing the list down) with a single
/// on-demand affordance — the list gets its space back until the user
/// actually wants to filter. Fills solid (ink900) once a filter is active,
/// so "something is filtered" is visible without opening the sheet.
class FilterTriggerButton extends StatelessWidget {
  const FilterTriggerButton({super.key, required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.ink900 : AppColors.surfaceCard,
          border: Border.all(color: active ? AppColors.ink900 : AppColors.borderSubtle),
          borderRadius: AppRadii.radiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.slidersHorizontal, size: 16, color: active ? AppColors.white : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              l10n.filtersTitle,
              style: TextStyle(
                fontFamily: plusJakartaSansFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
