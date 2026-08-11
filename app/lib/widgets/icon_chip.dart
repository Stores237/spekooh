import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

enum IconChipTint { blue, amber, green, purple, red }

/// Small tinted rounded-square wrapping one icon glyph — precedes almost
/// every list-row title in Spekooh. Ported from components/core/IconChip.jsx.
class IconChip extends StatelessWidget {
  const IconChip({super.key, required this.icon, this.tint = IconChipTint.blue, this.size = 44});

  final IconData icon;
  final IconChipTint tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tint) {
      case IconChipTint.blue:
        bg = AppColors.blue100;
        fg = AppColors.blue600;
      case IconChipTint.amber:
        bg = AppColors.amber100;
        fg = AppColors.amber600;
      case IconChipTint.green:
        bg = AppColors.green100;
        fg = AppColors.green600;
      case IconChipTint.purple:
        bg = AppColors.purple100;
        fg = AppColors.purple500;
      case IconChipTint.red:
        bg = AppColors.red100;
        fg = AppColors.red500;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.radiusChip),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: size * 0.45),
    );
  }
}
