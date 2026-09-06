import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'spekooh_button.dart';

/// A full-tab "this needs a real account" placeholder — owner decision
/// (2026-09-06): viewing papers/reports is no longer guest-accessible at
/// all (only contributing one still is; see PaperSubmissionViewSet's own
/// permission comment on the backend). Shown in place of PapersScreen for
/// a guest, same honest-empty-state tone as the rest of this app rather
/// than letting a guest drill down into a screen that will just 401.
class AccountRequiredView extends StatelessWidget {
  const AccountRequiredView({super.key, required this.body, this.onLogin});

  final String body;
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.lock, size: 40, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.space3),
                Text(l10n.accountRequiredTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(body, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.space4),
                SpekoohButton(size: SpekoohButtonSize.sm, onPressed: onLogin, child: Text(l10n.logIn)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
