import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class Achievement {
  const Achievement({
    required this.icon,
    required this.label,
    required this.earned,
    this.description = '',
    this.earnedColor = AppColors.gold600,
  });
  final IconData icon;
  final String label;
  final bool earned;

  /// The icon's color once earned (e.g. each flame tier's own fire color).
  /// A locked badge is always drawn in [lockedColor] instead, so "unlocked"
  /// is visible at a glance and not only through a faded opacity.
  final Color earnedColor;
  static const lockedColor = AppColors.textTertiary;

  Color get iconColor => earned ? earnedColor : lockedColor;

  /// What this badge is actually for — shown in the "All badges" list (see
  /// AchievementsSheet). Empty for mock/test data that doesn't need it.
  final String description;
}
