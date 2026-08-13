import 'package:flutter/material.dart';
import '../../data/auth_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/list_item_row.dart';
import '../common/circular_back_button.dart';

/// Ported from ui_kits/spekooh-app/SettingsScreen.jsx. `onLogin` is called
/// by the bottom "Log in" button (shown to guests); `onLogout` by "Log out"
/// (shown once actually logged in) — RootShell flips `isLoggedIn` for both.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onLogin, this.onLogout, this.onOpenPaywall});

  final VoidCallback? onLogin;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenPaywall;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _lang = 'en';

  @override
  Widget build(BuildContext context) {
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
                      Text('Settings', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                      Text('Account & app', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
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
                        child: const Icon(Icons.star, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Spekooh Pro', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                            Text('Unlimited paper views · no ads', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              _sectionLabel('Language'),
              _card([
                _langRow('English', 'en'),
                const Divider(height: 1),
                _langRow('Français', 'fr'),
              ]),
              _sectionLabel('Help'),
              _card(const [
                ListItemRow(icon: IconChip(icon: Icons.phone_outlined, tint: IconChipTint.blue, size: 38), title: 'Help & support', subtitle: 'Chat with a real person'),
                Divider(height: 1),
                ListItemRow(icon: IconChip(icon: Icons.chat_bubble_outline, tint: IconChipTint.blue, size: 38), title: 'Join our WhatsApp group', subtitle: 'Tips & updates'),
                Divider(height: 1),
                ListItemRow(icon: IconChip(icon: Icons.person_outline, tint: IconChipTint.blue, size: 38), title: 'Contact us', subtitle: 'Questions or feedback'),
              ]),
              _sectionLabel('About'),
              _card(const [
                ListItemRow(icon: IconChip(icon: Icons.language_outlined, tint: IconChipTint.blue, size: 38), title: 'Visit our website', subtitle: 'spekooh.app'),
                Divider(height: 1),
                ListItemRow(icon: IconChip(icon: Icons.lock_outline, tint: IconChipTint.blue, size: 38), title: 'Privacy policy'),
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
                    child: Text('Log out', style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.red500, fontWeight: FontWeight.w700, fontSize: 15)),
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
                    child: Text('Log in', style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15)),
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
    return InkWell(
      onTap: () => setState(() => _lang = code),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            const Icon(Icons.language_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary))),
            if (_lang == code) const Icon(Icons.check),
          ],
        ),
      ),
    );
  }
}
