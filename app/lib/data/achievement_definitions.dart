import 'package:flutter/widgets.dart' show IconData;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/achievement.dart';
import '../models/spekooh_user.dart';

/// Real badge tiers (owner decision, 2026-08-28) — adapting the badges
/// design already sketched in this app's own ui_kit mockup
/// (ui_kits/spekooh-app/ProfileScreen.jsx uses these exact four names) into
/// something backed by real, honest criteria instead of always-empty data.
/// Computed purely client-side from counts ProfileScreen already fetches
/// (submissionsCount, quizzesCount) — the same "compose from
/// already-existing endpoints" pattern HttpProfileRepository.getUser uses,
/// rather than a new backend achievements endpoint/model. Thresholds are
/// illustrative defaults — easy to retune in one place, and safe to add
/// more tiers to later since the "All N" count (see badgesSectionCount)
/// always reflects however many are actually defined here.
///
/// Deliberately l10n-free (structural data only) — human-readable
/// descriptions are looked up by [label] in the UI layer, see
/// AchievementsSheet.describeAchievement, so this stays a plain data/logic
/// module ProfileRepository implementations can use without needing a
/// BuildContext.
class AchievementDefinition {
  const AchievementDefinition({required this.icon, required this.label, this.minSubmissions = 0, this.minQuizzes = 0});

  final IconData icon;
  final String label;
  final int minSubmissions;
  final int minQuizzes;

  bool isEarnedBy(SpekoohUser user) => user.submissionsCount >= minSubmissions && user.quizzesCount >= minQuizzes;
}

const achievementDefinitions = [
  AchievementDefinition(icon: LucideIcons.flame, label: 'Spark', minSubmissions: 1),
  AchievementDefinition(icon: LucideIcons.flame, label: 'Ember', minSubmissions: 5),
  AchievementDefinition(icon: LucideIcons.flame, label: 'Inferno', minSubmissions: 15),
  AchievementDefinition(icon: LucideIcons.bookOpen, label: 'Scholar I', minQuizzes: 10),
];

List<Achievement> computeAchievements(SpekoohUser user) =>
    achievementDefinitions.map((d) => Achievement(icon: d.icon, label: d.label, earned: d.isEarnedBy(user))).toList();
