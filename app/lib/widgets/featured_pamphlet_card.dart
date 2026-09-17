import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/pamphlet.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import 'pamphlet_cover_image.dart';
import 'spekooh_button.dart';

/// The shop's featured pamphlet, shown on Home to prompt a real purchase —
/// owner-provided reference (a competitor's richer "cover + description +
/// inline Buy" layout, 2026-09-16), adapted to Spekooh's own design system.
/// Cover image handling lives in PamphletCoverImage, shared with the
/// Pamphlet Shop grid.
class FeaturedPamphletCard extends StatelessWidget {
  const FeaturedPamphletCard({super.key, required this.pamphlet, this.onTap});

  final Pamphlet pamphlet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PamphletCoverImage(pamphlet: pamphlet, width: 76, height: 96),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pamphlet.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  if (pamphlet.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pamphlet.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          children: [TextSpan(text: '${pamphlet.priceFcfa} '), TextSpan(text: 'FCFA', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600))],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SpekoohButton(size: SpekoohButtonSize.sm, onPressed: onTap, child: Text(l10n.buy)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
