import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../common/circular_back_button.dart';
import 'terms_of_service_content.dart';

/// Real content (2026-09-13, owner blocker) — reached from the signup
/// checkbox's own label, which previously named a document with no
/// screen, route, or content anywhere in the app: users were agreeing to
/// terms they had no way to actually read. Same structure as
/// PrivacyPolicyScreen (its own sibling link, right below this one on the
/// checkbox) — see terms_of_service_content.dart for the text itself and
/// what each section is grounded in.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
                  Text(l10n.termsOfServiceTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.termsOfServiceLastUpdated(termsOfServiceLastUpdated),
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                termsOfServiceIntro,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              ),
              for (final section in termsOfServiceSections) ...[
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
