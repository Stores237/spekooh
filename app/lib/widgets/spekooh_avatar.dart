import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Circular avatar for the "Top players" leaderboard. Falls back to
/// initials on a gold tint when no image. Rank 1 gets a small star above
/// and a gold ring instead of white. Ported from
/// components/data-display/Avatar.jsx.
class SpekoohAvatar extends StatelessWidget {
  const SpekoohAvatar({super.key, this.imageUrl, this.name, this.rank, this.size = 44});

  final String? imageUrl;
  final String? name;
  final int? rank;
  final double size;

  String get _initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;
    return SizedBox(
      width: size,
      height: size + (isTop ? 14 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue400,
                border: Border.all(
                  color: isTop ? AppColors.amber500 : AppColors.white,
                  width: 2,
                ),
                image: imageUrl != null
                    ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              alignment: Alignment.center,
              child: imageUrl == null
                  ? Text(
                      _initials,
                      style: TextStyle(
                        fontFamily: plusJakartaSansFamily,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: size * 0.36,
                      ),
                    )
                  : null,
            ),
          ),
          if (isTop)
            const Positioned(
              top: 0,
              child: Text('★', style: TextStyle(fontSize: 14, color: AppColors.gold500)),
            ),
        ],
      ),
    );
  }
}
