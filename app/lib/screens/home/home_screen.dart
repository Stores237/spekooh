import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_badge.dart';
import '../../widgets/spekooh_button.dart';
import '../../widgets/icon_chip.dart';

/// Ported from ui_kits/spekooh-app/HomeScreen.jsx — the guest (logged-out)
/// Home tab. Callbacks are optional so this screen previews standalone in
/// tests/gallery; RootShell wires the real ones in the navigation stage.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onOpenPaywall,
    this.onOpenSettings,
    this.onOpenPaper,
    this.onOpenPamphlet,
    this.onOpenProfile,
    this.onOpenNotes,
    this.onOpenShop,
  });

  final VoidCallback? onOpenPaywall;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenPaper;
  final VoidCallback? onOpenPamphlet;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenShop;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onOpenProfile,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold200),
                          alignment: Alignment.center,
                          child: Text('G', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, color: AppColors.gold700)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bienvenue · Welcome', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                            Text('Guest', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      SpekoohButton(variant: SpekoohButtonVariant.secondary, size: SpekoohButtonSize.sm, onPressed: () {}, child: const Text('Join free')),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onOpenSettings,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white, border: Border.all(color: AppColors.borderSubtle)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.settings_outlined, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              const Row(children: [
                SpekoohBadge(text: 'Exploring — no account', tone: SpekoohBadgeTone.neutral),
                SizedBox(width: 6),
                SpekoohBadge(text: 'EN / FR', tone: SpekoohBadgeTone.blue),
              ]),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FREE PAPER VIEWS TODAY', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.white),
                        children: const [TextSpan(text: '2 '), TextSpan(text: 'of 3 used', style: TextStyle(fontSize: 13, color: AppColors.textOnDarkMuted, fontWeight: FontWeight.w400))],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Watch an ad for 1 more, or go Pro for unlimited views.', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.14),
                              foregroundColor: AppColors.white,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text('Watch ad', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SpekoohButton(size: SpekoohButtonSize.sm, onPressed: onOpenPaywall, child: const Text('Go Pro')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              InkWell(
                onTap: onOpenPaper,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                  child: Row(
                    children: [
                      const IconChip(icon: Icons.functions, tint: IconChipTint.purple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mathématiques · Baccalauréat 2025', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                            Text('Free to view — marking guide sold separately', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              Text('Contribution — earn credit', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.space3),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconChip(icon: Icons.upload_outlined, tint: IconChipTint.amber, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Got a past paper or report we don\'t have?', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                          Text('Snap a photo, tag it, earn bonus credit once it\'s verified — first contribution counts.', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              Row(
                children: [
                  Expanded(child: _tile(icon: Icons.menu_book_outlined, tint: IconChipTint.green, title: 'Notes', subtitle: 'Topic study notes by subject', onTap: onOpenNotes)),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(child: _tile(icon: Icons.shopping_bag_outlined, tint: IconChipTint.amber, title: 'Shop', subtitle: 'Partner pamphlets, QR pickup', onTap: onOpenShop)),
                ],
              ),
              const SizedBox(height: AppSpacing.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Partner pamphlets', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                  GestureDetector(onTap: onOpenShop, child: Text('Shop', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.gold700))),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              InkWell(
                onTap: onOpenPamphlet,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                  child: Row(
                    children: [
                      Container(width: 64, height: 64, decoration: BoxDecoration(gradient: AppGradients.goldDeep, borderRadius: BorderRadius.circular(10))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Probatoire Philosophy Pamphlet', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                            Text('Sold by Librairie Centrale · pick up with a QR code.', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                    children: const [TextSpan(text: '7,500 '), TextSpan(text: 'FCFA', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600))],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SpekoohButton(size: SpekoohButtonSize.sm, onPressed: onOpenPamphlet, child: const Text('Buy')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              Text('SIGN UP ONLY WHEN YOU WANT TO…', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.7)),
              const SizedBox(height: AppSpacing.space3),
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _lockedRow(Icons.local_fire_department_outlined, 'Earn & redeem contributor credits'),
                    const Divider(height: 1),
                    _lockedRow(Icons.fact_check_outlined, 'Track your contributions'),
                    const Divider(height: 1),
                    _lockedRow(Icons.notifications_none, 'Get instructor status alerts'),
                    const Divider(height: 1),
                    _lockedRow(Icons.download_outlined, 'Sync downloads across phones'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Reading papers stays open to everyone — 3 free views a day, no account needed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({required IconData icon, required IconChipTint tint, required String title, required String subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconChip(icon: icon, tint: tint, size: 40),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _lockedRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconChip(icon: icon, tint: IconChipTint.blue, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary))),
          const Icon(Icons.lock_outline, size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
