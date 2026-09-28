import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radii.dart';
import '../theme/app_theme.dart';

/// Gold "PRO" pill shown next to a Spekooh Pro subscriber's name on Profile.
/// Deliberately a different shape from [SpekoohBadge] (gradient fill + crown,
/// not a flat tag) so it reads as a status the user has, not another metadata
/// count like "3 papers".
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.proBadgeSemantics,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: const BoxDecoration(gradient: AppGradients.goldDeep, borderRadius: AppRadii.radiusPill),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.crown, size: 11, color: AppColors.white),
            const SizedBox(width: 4),
            Text(
              l10n.proBadgeLabel,
              style: TextStyle(
                fontFamily: plusJakartaSansFamily,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
