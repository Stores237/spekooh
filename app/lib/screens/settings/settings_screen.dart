import 'dart:async';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import '../../data/auth_session.dart';
import '../../data/locale_controller.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/list_item_row.dart';
import '../../sheets/password_reset_sheet.dart';
import '../common/circular_back_button.dart';

/// Ported from ui_kits/spekooh-app/SettingsScreen.jsx. `onLogin` is called
/// by the bottom "Log in" button (shown to guests); `onLogout` by "Log out"
/// (shown once actually logged in) — RootShell flips `isLoggedIn` for both.
class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key, this.onLogin, this.onLogout, this.onOpenPaywall, ProfileRepository? profileRepository})
      : profileRepository = profileRepository ?? RepositoryLocator.instance.profile;

  final VoidCallback? onLogin;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenPaywall;
  final ProfileRepository profileRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Real support destinations (owner-provided, 2026-08-23) — the same phone
  // number doubles as the WhatsApp support line, so "Help & support" places
  // a call while the WhatsApp row opens a chat on that same number, rather
  // than the two rows duplicating one action.
  static const _supportPhone = '+237659802679';
  static const _supportWhatsapp = '237659802679';
  static const _supportEmail = 'storefix237@gmail.com';

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenLink)));
    }
  }

  Future<void> _changeLanguage(String code) async {
    await LocaleController.instance.setLocale(code);
    if (AuthSession.instance.isLoggedIn) {
      // Best-effort — the local switch already happened; a failed sync just
      // means this device's choice won't yet be mirrored to the account.
      unawaited(widget.profileRepository.setLanguagePreference(code).catchError((_) {}));
    }
  }

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.settingsTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                      Text(l10n.settingsSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              InkWell(
                onTap: widget.onOpenPaywall,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.gold200, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.star, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.spekoohProTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                            Text(l10n.spekoohProSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              // Previously the only way to reach PasswordResetSheet at all
              // was AuthSheet's "Forgot password?" link — which only shows
              // while logged OUT. A logged-in user had no way to change
              // their password. Reuses the same OTP sheet: it re-verifies
              // via an emailed code, not the current password, so it works
              // identically whether "forgotten" or just "want to change it".
              if (AuthSession.instance.isLoggedIn) ...[
                _sectionLabel(l10n.accountSection),
                _card([
                  ListItemRow(
                    icon: const IconChip(icon: LucideIcons.lock, tint: IconChipTint.blue, size: 38),
                    title: l10n.changePasswordTitle,
                    subtitle: l10n.changePasswordSubtitle,
                    onTap: () => showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PasswordResetSheet(),
                    ),
                  ),
                ]),
              ],
              _sectionLabel(l10n.languageSection),
              _card([
                _langRow('English', 'en'),
                const Divider(height: 1),
                _langRow('Français', 'fr'),
              ]),
              _sectionLabel(l10n.helpSection),
              _card([
                ListItemRow(
                  icon: const IconChip(icon: LucideIcons.phone, tint: IconChipTint.blue, size: 38),
                  title: l10n.helpSupportTitle,
                  subtitle: l10n.helpSupportSubtitle,
                  onTap: () => _launch(Uri(scheme: 'tel', path: _supportPhone)),
                ),
                const Divider(height: 1),
                ListItemRow(
                  icon: const IconChip(icon: LucideIcons.messageCircle, tint: IconChipTint.blue, size: 38),
                  title: l10n.helpWhatsappTitle,
                  subtitle: l10n.helpWhatsappSubtitle,
                  onTap: () => _launch(Uri.parse('https://wa.me/$_supportWhatsapp')),
                ),
                const Divider(height: 1),
                ListItemRow(
                  icon: const IconChip(icon: LucideIcons.user, tint: IconChipTint.blue, size: 38),
                  title: l10n.helpContactTitle,
                  subtitle: l10n.helpContactSubtitle,
                  onTap: () => _launch(Uri(scheme: 'mailto', path: _supportEmail)),
                ),
              ]),
              _sectionLabel(l10n.aboutSection),
              _card([
                // No live site yet (owner-confirmed, 2026-08-23) — honest
                // "not available" subtitle instead of a domain that doesn't
                // resolve to anything, and no onTap until one exists.
                ListItemRow(icon: const IconChip(icon: LucideIcons.globe, tint: IconChipTint.blue, size: 38), title: l10n.aboutWebsiteTitle, subtitle: l10n.notAvailableYet),
                const Divider(height: 1),
                ListItemRow(icon: const IconChip(icon: LucideIcons.lock, tint: IconChipTint.blue, size: 38), title: l10n.aboutPrivacyTitle),
              ]),
              const SizedBox(height: AppSpacing.space6),
              if (AuthSession.instance.isLoggedIn)
                GestureDetector(
                  onTap: widget.onLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.red500),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(l10n.logOut, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.red500, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                )
              else
                GestureDetector(
                  onTap: widget.onLogin,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: AppShadows.button,
                    ),
                    alignment: Alignment.center,
                    child: Text(l10n.logIn, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space5, bottom: AppSpacing.space2),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.06 * 11),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: children),
      );

  Widget _langRow(String label, String code) {
    // Language names are shown as autonyms (each language's own name for
    // itself) — standard convention, so "English" and "Français" never get
    // translated based on the current UI language.
    final active = LocaleController.instance.locale.languageCode == code;
    return InkWell(
      onTap: active ? null : () => _changeLanguage(code),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            const Icon(LucideIcons.globe),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary))),
            if (active) const Icon(LucideIcons.check),
          ],
        ),
      ),
    );
  }
}
