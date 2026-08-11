import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_button.dart';

/// Ported from ui_kits/spekooh-app/LoggedInHomeScreen.jsx.
class LoggedInHomeScreen extends StatelessWidget {
  const LoggedInHomeScreen({
    super.key,
    this.onOpenSettings,
    this.onOpenPaper,
    this.onOpenSubmit,
    this.onOpenNotifications,
    this.onOpenProfile,
    this.onOpenNotes,
    this.onOpenShop,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenPaper;
  final VoidCallback? onOpenSubmit;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenShop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full-bleed dark hero — no horizontal padding on the outer
              // scroll view, so this naturally spans the full width; all
              // content below it is individually wrapped in a Padding.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPad, AppSpacing.space4, AppSpacing.screenPad, 40),
                decoration: const BoxDecoration(
                  color: AppColors.ink900,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  child: Text('K', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, color: AppColors.gold700)),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Good morning', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12)),
                                    Text('Kkk', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
                                      child: Text('EN', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink900)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      child: Text('FR', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.white)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _darkIconButton(Icons.settings_outlined, onOpenSettings),
                              const SizedBox(width: 8),
                              _darkIconButton(Icons.notifications_none, onOpenNotifications),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                            child: const Text('GCE A LEVEL · SCIENCE', style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.gold500, borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.local_fire_department, size: 12, color: AppColors.ink900),
                                SizedBox(width: 4),
                                Text('START A STREAK', style: TextStyle(color: AppColors.ink900, fontSize: 11, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Transform.translate(
                offset: const Offset(0, -24),
                child: InkWell(
                  onTap: onOpenPaper,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.green500, width: 3)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.track_changes_outlined, size: 20, color: AppColors.green500),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRACTICE MODE', style: TextStyle(color: AppColors.green600, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                              Text('Learn without countdown pressure', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                              Text('Start with a paper, quiz, or ask the AI assistant something.', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YOUR FREE TRIAL', style: TextStyle(color: AppColors.gold700, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold50),
                            alignment: Alignment.center,
                            child: const Icon(Icons.check, size: 12, color: AppColors.gold700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Open your first marking guide free', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                            child: const Text('7 days left', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Unlimited paper views · offline downloads · AI assistant', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: SpekoohButton(onPressed: () {}, child: const Text('Keep my access'))),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                  children: [
                    _quickAction(Icons.description_outlined, 'Papers', null),
                    _quickAction(Icons.menu_book_outlined, 'Notes', onOpenNotes),
                    _quickAction(Icons.upload_outlined, 'Contribute', onOpenSubmit),
                    _quickAction(Icons.shopping_bag_outlined, 'Shop', onOpenShop),
                    _quickAction(Icons.chat_bubble_outline, 'Forum', null),
                    _quickAction(Icons.download_outlined, 'Offline', null),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily challenge', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            const SizedBox(height: 2),
                            const Text('5-minute mixed quiz · earn +50 XP', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 11)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: AppColors.gold500, borderRadius: BorderRadius.circular(999)),
                              child: const Text('Play now', style: TextStyle(color: AppColors.ink900, fontWeight: FontWeight.w800, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.15)),
                      Expanded(
                        child: Column(
                          children: const [
                            Icon(Icons.local_fire_department_outlined, size: 22, color: AppColors.gold500),
                            SizedBox(height: 4),
                            Text('Start', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            Text('Play a quiz to begin', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ready offline', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                  Text('Downloads · 1', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold700)),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.download_outlined, size: 18, color: AppColors.green600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Biology O-Level marking guide', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                          const Text('✓ OFFLINE READY', style: TextStyle(fontSize: 11, color: AppColors.green600, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _darkIconButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
        alignment: Alignment.center,
        child: Icon(icon, size: 15, color: AppColors.white),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.gold700),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
