import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/pamphlet.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import 'spekooh_button.dart';

/// The shop's featured pamphlet, shown on Home to prompt a real purchase —
/// owner-provided reference (a competitor's richer "cover + description +
/// inline Buy" layout, 2026-09-16), adapted to Spekooh's own design system.
/// The 76x96 cover slot shows the real photo Integration Ops uploaded
/// (owner request, 2026-09-17), cropped to fit rather than stretched —
/// falling back to our gold brand gradient with the real subjectTitle/
/// academicLevel (not a fabricated placeholder) whenever one hasn't been
/// uploaded yet, or fails to load.
class FeaturedPamphletCard extends StatelessWidget {
  const FeaturedPamphletCard({super.key, required this.pamphlet, this.onTap});

  static const _coverWidth = 76.0;
  static const _coverHeight = 96.0;

  final Pamphlet pamphlet;
  final VoidCallback? onTap;

  Widget _coverPlaceholder() {
    return Container(
      width: _coverWidth,
      height: _coverHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(gradient: AppGradients.goldDeep, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (pamphlet.subjectTitle.isNotEmpty)
            Text(
              pamphlet.subjectTitle.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.white, height: 1.15),
            ),
          if (pamphlet.academicLevel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
              child: Text(
                pamphlet.academicLevel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 9, color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cover() {
    final url = pamphlet.coverImageUrl;
    if (url == null || url.isEmpty) return _coverPlaceholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: _coverWidth,
        height: _coverHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _coverPlaceholder(),
      ),
    );
  }

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
            _cover(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pamphlet.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  Text(l10n.homePamphletSoldBy(pamphlet.partner), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
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
