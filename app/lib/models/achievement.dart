import 'package:flutter/material.dart';

class Achievement {
  const Achievement({required this.icon, required this.label, required this.earned, this.description = ''});
  final IconData icon;
  final String label;
  final bool earned;

  /// What this badge is actually for — shown in the "All badges" list (see
  /// AchievementsSheet). Empty for mock/test data that doesn't need it.
  final String description;
}
