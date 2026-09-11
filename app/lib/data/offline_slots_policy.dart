import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'repositories/profile_repository.dart';

/// "Download slots" (My Downloads mockup, owner request 2026-09-11): a
/// free account may keep this many papers offline at once, and separately
/// this many corrections (marking guides) offline at once — the two
/// stores are capped independently, not shared. A Kawlo Plus subscriber
/// has no cap at all ("unlimited downloads").
const kMaxOfflineSlots = 3;

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
  final isPlus = (await profileRepository.getUser()).isPlusSubscriber;
  if (isPlus || currentCount < kMaxOfflineSlots) return true;
  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(l10n))));
  return false;
}
