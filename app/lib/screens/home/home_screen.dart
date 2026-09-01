import 'package:flutter/material.dart';
import '../../data/repositories/papers_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/paper_entry.dart';
import '../../models/pamphlet.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_badge.dart';
import '../../widgets/spekooh_button.dart';
import '../../widgets/spekooh_loader.dart';
import '../../widgets/icon_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ported from ui_kits/spekooh-app/HomeScreen.jsx — the guest (logged-out)
/// Home tab. Callbacks are optional so this screen previews standalone in
/// tests/gallery; RootShell wires the real ones in the navigation stage.
class HomeScreen extends StatelessWidget {
  HomeScreen({
    super.key,
    this.onOpenPaywall,
    this.onOpenSettings,
    this.onOpenPaper,
    this.onOpenPamphlet,
    this.onOpenProfile,
    this.onOpenNotes,
    this.onOpenShop,
    this.onOpenSubmit,
    PapersRepository? papersRepository,
    ShopRepository? shopRepository,
  })  : papersRepository = papersRepository ?? RepositoryLocator.instance.papers,
        shopRepository = shopRepository ?? RepositoryLocator.instance.shop;

  final VoidCallback? onOpenPaywall;
  final VoidCallback? onOpenSettings;
  final ValueChanged<PaperEntry>? onOpenPaper;
  final VoidCallback? onOpenPamphlet;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenSubmit;
  final PapersRepository papersRepository;
  final ShopRepository shopRepository;

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
                            Text(l10n.homeWelcomeGreeting, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                            Text(l10n.guestLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      SpekoohButton(variant: SpekoohButtonVariant.secondary, size: SpekoohButtonSize.sm, onPressed: onOpenSettings, child: Text(l10n.joinFree)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onOpenSettings,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white, border: Border.all(color: AppColors.borderSubtle)),
                          alignment: Alignment.center,
                          child: const Icon(LucideIcons.settings, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Row(children: [
                SpekoohBadge(text: l10n.homeExploringBadge, tone: SpekoohBadgeTone.neutral),
                const SizedBox(width: 6),
                const SpekoohBadge(text: 'EN / FR', tone: SpekoohBadgeTone.blue),
              ]),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.homeFreeViewsLabel, style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    const SizedBox(height: 4),
                    Text(l10n.homeFreeViewsCount, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.white)),
                    const SizedBox(height: 6),
                    // No account means no server-side counter to check against — a
                    // live "N of 3 used" figure would just be fabricated for guests.
                    Text(l10n.homeFreeViewsHint, style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SpekoohButton(size: SpekoohButtonSize.sm, onPressed: onOpenPaywall, child: Text(l10n.goPro)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              FutureBuilder<PaperEntry?>(
                future: papersRepository.getLatestPublished(),
                builder: (context, snapshot) {
                  final paper = snapshot.data;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 64, child: SpekoohLoader());
                  }
                  if (paper == null) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                      child: Text(l10n.homeNoPapersYet, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                    );
                  }
                  final label = [paper.subjectTitle, paper.examTypeName].whereType<String>().join(' · ');
                  return InkWell(
                    onTap: () => onOpenPaper?.call(paper),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                      child: Row(
                        children: [
                          const IconChip(icon: LucideIcons.sigma, tint: IconChipTint.purple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.homePaperLabelWithYear(label, paper.year), style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                // Reports have no marking-guide/instructor
                                // pipeline at all, unlike exam papers — the
                                // "marking guide sold separately" line would
                                // be a false claim for one.
                                Text(
                                  paper.isReport
                                      ? (paper.requiresUnlock ? l10n.homeReportPaymentRequired : l10n.homeFreeToViewReport)
                                      : l10n.homeFreeToView,
                                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(l10n.homeContributionTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.space3),
              GestureDetector(
                onTap: onOpenSubmit,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconChip(icon: LucideIcons.upload, tint: IconChipTint.amber, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.homeContributionPrompt, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                            Text(l10n.homeContributionSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (onOpenSubmit != null) const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              Row(
                children: [
                  Expanded(child: _tile(icon: LucideIcons.bookOpen, tint: IconChipTint.green, title: l10n.notesTitle, subtitle: l10n.notesSubtitle, onTap: onOpenNotes)),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(child: _tile(icon: LucideIcons.shoppingBag, tint: IconChipTint.amber, title: l10n.shopTitle, subtitle: l10n.shopSubtitle, onTap: onOpenShop)),
                ],
              ),
              const SizedBox(height: AppSpacing.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.partnerPamphletsTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                  GestureDetector(onTap: onOpenShop, child: Text(l10n.shopTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.gold700))),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              FutureBuilder<Pamphlet?>(
                future: shopRepository.getFeaturedPamphlet().then<Pamphlet?>((p) => p).catchError((_) => null),
                builder: (context, snapshot) {
                  final pamphlet = snapshot.data;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 64, child: SpekoohLoader());
                  }
                  if (pamphlet == null) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                      child: Text(l10n.homeNoPamphlet, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                    );
                  }
                  return InkWell(
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
                                Text(pamphlet.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                Text(l10n.homePamphletSoldBy(pamphlet.partner), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                        children: [TextSpan(text: '${pamphlet.priceFcfa} '), TextSpan(text: 'FCFA', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600))],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SpekoohButton(size: SpekoohButtonSize.sm, onPressed: onOpenPamphlet, child: Text(l10n.buy)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(l10n.homeSignUpPrompt, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.7)),
              const SizedBox(height: AppSpacing.space3),
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _lockedRow(LucideIcons.flame, l10n.homeLockedCredits),
                    const Divider(height: 1),
                    _lockedRow(LucideIcons.clipboardCheck, l10n.homeLockedTrackContributions),
                    const Divider(height: 1),
                    _lockedRow(LucideIcons.bell, l10n.homeLockedInstructorAlerts),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.homeReadingOpenNote,
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
          const Icon(LucideIcons.lock, size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
