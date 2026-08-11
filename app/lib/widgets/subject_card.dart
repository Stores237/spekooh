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
        padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: plusJakartaSansFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
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
