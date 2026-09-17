import 'package:flutter/material.dart';

import '../models/pamphlet.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';

/// Shared cover slot for a Pamphlet, used by both FeaturedPamphletCard and
/// the Pamphlet Shop grid (owner reference, 2026-09-17) -- always cropped
/// to [width]x[height] via BoxFit.cover, falling back to the gold subject/
/// academicLevel placeholder (real data, never fabricated) whenever no
/// cover_image has been uploaded yet, or it fails to load.
class PamphletCoverImage extends StatelessWidget {
  const PamphletCoverImage({super.key, required this.pamphlet, required this.width, required this.height, this.borderRadius = const BorderRadius.all(Radius.circular(12))});

  final Pamphlet pamphlet;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(gradient: AppGradients.goldDeep, borderRadius: borderRadius),
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

  @override
  Widget build(BuildContext context) {
    final url = pamphlet.coverImageUrl;
    if (url == null || url.isEmpty) return _placeholder();
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      ),
    );
  }
}
