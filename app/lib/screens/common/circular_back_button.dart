import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The small circular icon button reused at the top of most pushed screens
/// (Notes, Notifications, Shop, Profile, ...) — chevron-left by default,
/// since that's what every other call site actually is (a real "back").
/// [icon] exists for the one call site that isn't a back action at all
/// (ProfileScreen's "open settings" button, previously showing the same
/// back-chevron as an actual back button right next to it — found from a
/// live screenshot, 2026-08-28) — pass a different icon there rather than
/// reusing the misleading default.
class CircularBackButton extends StatelessWidget {
  const CircularBackButton({super.key, required this.onTap, this.icon = LucideIcons.chevronLeft});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
