import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'repositories/profile_repository.dart';

/// "Download slots" (My Downloads mockup, owner request 2026-09-11): a
/// free account may keep this many papers offline at once, and separately
/// this many corrections (marking guides) offline at once — the two
/// stores are capped independently, not shared. A Kawlo Plus subscriber
/// has no cap at all ("unlimited downloads").
const kMaxOfflineSlots = 3;

/// The real cap for one store, accounting for a redeemed XP slot bonus
/// (see apps.xp.services.redeem_slot_bonus on the backend) — +1 on top of
/// the free-tier cap while [hasActiveSlotBonus] is true. Meaningless for a
/// Plus subscriber, who has no cap at all regardless. Takes the bool
/// directly rather than a whole SpekoohUser so callers with only a
/// still-loading (nullable) user can pass `user?.hasActiveSlotBonus ?? false`.
int effectiveMaxOfflineSlots(bool hasActiveSlotBonus) => kMaxOfflineSlots + (hasActiveSlotBonus ? 1 : 0);

/// Shared by both the paper-save flow (paper_detail_screen) and the
/// marking-guide-save flow (marking_guide_screen) so the two never drift.
/// Returns true if the caller may proceed with save(); false means this
/// already told the user why not (a SnackBar) — [errorMessage] lets each
/// caller supply its own store-specific wording (papers vs corrections).
/// Takes [profileRepository] explicitly rather than reaching into
/// RepositoryLocator.instance itself — callers already take their own
/// repository as a constructor param (for exactly this reason: a widget
/// test that builds the screen directly, bypassing RepositoryLocator
/// entirely, must not have this reach out to a real backend).
Future<bool> confirmOfflineSlotAvailable(
  BuildContext context, {
  required int currentCount,
  required ProfileRepository profileRepository,
  required String Function(AppLocalizations l10n) errorMessage,
}) async {
  final user = await profileRepository.getUser();
  if (user.isPlusSubscriber || currentCount < effectiveMaxOfflineSlots(user.hasActiveSlotBonus)) return true;
  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(l10n))));
  return false;
}
