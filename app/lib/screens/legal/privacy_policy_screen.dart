import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../common/circular_back_button.dart';
import 'privacy_policy_content.dart';

/// Real content (owner decision, 2026-08-28, adapting a shared reference
/// policy) — reached from Settings' "Privacy policy" row, which previously
/// had no onTap at all, and from the "Privacy Policy" link on the signup
/// terms checkbox, which previously asked users to agree to a document
/// they had no way to actually read. See privacy_policy_content.dart for
/// the text itself and what backs each claim.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  CircularBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.space3),
                  Text(l10n.aboutPrivacyTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.privacyPolicyLastUpdated(privacyPolicyLastUpdated),
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                privacyPolicyIntro,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              ),
              for (final section in privacyPolicySections) ...[
                const SizedBox(height: AppSpacing.space5),
                Text(
                  section.heading,
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  section.body,
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }
}
