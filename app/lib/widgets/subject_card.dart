import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// Grid tile used in "Choose a subject" screens, 2-per-row. A small numeric
/// code sits top-right; a small uppercase green tag sits bottom-left.
/// Ported from components/data-display/SubjectCard.jsx.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.code,
    this.onTap,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final String? code;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.radiusLg,
      child: Container(
        width: double.infinity,
        // 16 all round left too little headroom once a 2-line title,
        // subtitle, and badge all stack up — see the maxLines note below.
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadii.radiusLg,
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            if (code != null)
              Positioned(
                top: 0,
                right: 0,
                child: Text(
                  code!,
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 6),
                Text(
                  title,
                  // Subject titles are real, sometimes contributor-typed free
                  // text (see SubjectSerializer.create) — some run long
                  // ("Fondation of data science and programming of data
                  // science"). Every card in the grid shares one fixed
                  // childAspectRatio, so an unbounded title previously
                  // overflowed past its own card into whatever sat below it
                  // (found from a live screenshot, 2026-08-28). Capped so
                  // every card in the grid stays a consistent height.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: plusJakartaSansFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: plusJakartaSansFamily,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (badgeText != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    badgeText!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: plusJakartaSansFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
