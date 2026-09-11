import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/offline_guides_store.dart';
import '../../data/offline_papers_store.dart';
import '../../data/offline_slots_policy.dart';
import '../../data/repositories/payments_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/offline_guide.dart';
import '../../models/offline_paper.dart';
import '../../models/spekooh_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// My Downloads (owner-provided mockup, 2026-09-11): saved papers and
/// saved corrections (marking guides) shown as two tabs, each capped at
/// [effectiveMaxOfflineSlots] for a free account, unlimited for Kawlo Plus.
/// Only ever reached from a home-page entry point shown once something has
/// actually been saved (see LoggedInHomeScreen) — this screen itself just
/// renders whatever OfflinePapersStore/OfflineGuidesStore already hold, it
/// doesn't gate its own visibility.
class MyDownloadsScreen extends StatefulWidget {
  MyDownloadsScreen({super.key, ProfileRepository? profileRepository, PaymentsRepository? paymentsRepository, this.onOpenPaywall})
      : profileRepository = profileRepository ?? RepositoryLocator.instance.profile,
        paymentsRepository = paymentsRepository ?? RepositoryLocator.instance.payments;

  final ProfileRepository profileRepository;
  final PaymentsRepository paymentsRepository;
  final VoidCallback? onOpenPaywall;

  @override
  State<MyDownloadsScreen> createState() => _MyDownloadsScreenState();
}

class _MyDownloadsScreenState extends State<MyDownloadsScreen> {
  late Future<SpekoohUser> _userFuture = widget.profileRepository.getUser();
  int _tab = 0;
  bool _redeeming = false;

  /// Re-fetches after a real redemption so xpBalance/hasActiveSlotBonus —
  /// and therefore the slots card's own effective cap — reflect it
  /// immediately, without leaving the screen and coming back.
  Future<void> _redeemSlotBonus(AppLocalizations l10n) async {
    setState(() => _redeeming = true);
    try {
      await widget.paymentsRepository.redeemSlotBonus();
      if (mounted) setState(() { _userFuture = widget.profileRepository.getUser(); });
    } on InsufficientXPError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([OfflinePapersStore.instance, OfflineGuidesStore.instance]),
          builder: (context, _) {
            final papers = OfflinePapersStore.instance.papers;
            final guides = OfflineGuidesStore.instance.guides;
            return FutureBuilder<SpekoohUser>(
              future: _userFuture,
              builder: (context, snapshot) {
                final user = snapshot.data;
                final isPlus = user?.isPlusSubscriber ?? false;
                final currentCount = _tab == 0 ? papers.length : guides.length;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.space2),
                      Row(
                        children: [
                          GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Padding(padding: EdgeInsets.only(top: 2), child: Icon(LucideIcons.chevronLeft))),
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.myDownloadsTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
                                Text(l10n.myDownloadsSubtitle(papers.length + guides.length), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Row(
                        children: [
                          _tabPill(l10n.downloadsPapersTabLabel, papers.length, 0),
                          const SizedBox(width: 10),
                          _tabPill(l10n.downloadsCorrectionsTabLabel, guides.length, 1),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      if (!isPlus) ...[
                        _slotsCard(l10n, currentCount, user),
                        const SizedBox(height: AppSpacing.space5),
                      ],
                      if (_tab == 0) _papersList(l10n, papers) else _guidesList(l10n, guides),
                      const SizedBox(height: AppSpacing.space6),
                      Text(l10n.getMoreSlotsTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
                      const SizedBox(height: AppSpacing.space3),
                      _xpRedeemCard(l10n, user),
                      if (!isPlus) ...[
                        const SizedBox(height: AppSpacing.space3),
                        _kawloPlusBanner(l10n),
                      ],
                      const SizedBox(height: AppSpacing.space6),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _tabPill(String label, int count, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(color: active ? AppColors.ink900 : AppColors.white, borderRadius: BorderRadius.circular(999), boxShadow: active ? null : AppShadows.card),
        child: Text('$label · $count', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, fontWeight: FontWeight.w700, color: active ? AppColors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _slotsCard(AppLocalizations l10n, int used, SpekoohUser? user) {
    final max = effectiveMaxOfflineSlots(user?.hasActiveSlotBonus ?? false);
    final clamped = used > max ? max : used;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.downloadSlotsTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                child: Text(l10n.downloadSlotsUsed(clamped, max), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < max; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(color: i < clamped ? AppColors.gold500 : AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _tab == 0 ? l10n.offlineSlotsFullPapersError(max) : l10n.offlineSlotsFullGuidesError(max),
            style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppLocalizations l10n, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(LucideIcons.download, size: 32, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(body, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _papersList(AppLocalizations l10n, List<OfflinePaper> papers) {
    if (papers.isEmpty) return _emptyState(l10n, l10n.noDownloadsYetPapers);
    return Column(
      children: [
        for (final paper in papers) ...[
          _downloadRow(title: paper.title, subtitle: paper.subtitle, onRemove: () => OfflinePapersStore.instance.remove(paper.paperId)),
          const SizedBox(height: AppSpacing.space3),
        ],
      ],
    );
  }

  Widget _guidesList(AppLocalizations l10n, List<OfflineGuide> guides) {
    if (guides.isEmpty) return _emptyState(l10n, l10n.noDownloadsYetGuides);
    return Column(
      children: [
        for (final guide in guides) ...[
          _downloadRow(title: guide.title, subtitle: l10n.markingGuideTitle, onRemove: () => OfflineGuidesStore.instance.remove(guide.paperId)),
          const SizedBox(height: AppSpacing.space3),
        ],
      ],
    );
  }

  Widget _downloadRow({required String title, required String subtitle, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(onTap: onRemove, child: const Icon(LucideIcons.trash2, size: 18, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  /// Real XP economy (owner request, 2026-09-11 — see backend
  /// apps.xp.services): earned from real QuizAttempts, spent here for a
  /// real +1 offline slot. [user] null means still loading — shown as a
  /// disabled button rather than a fabricated balance in that instant.
  Widget _xpRedeemCard(AppLocalizations l10n, SpekoohUser? user) {
    final active = user?.hasActiveSlotBonus ?? false;
    final canRedeem = !active && !_redeeming && (user?.xpBalance ?? 0) >= 250;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.gold50, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.sparkles, size: 18, color: AppColors.gold700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.xpRedeemSlotTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                Text(
                  active ? l10n.xpSlotBonusActiveLabel : l10n.xpYouHaveLabel(user?.xpBalance ?? 0),
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: active ? AppColors.green600 : AppColors.textSecondary, fontWeight: active ? FontWeight.w700 : FontWeight.w400),
                ),
              ],
            ),
          ),
          if (!active)
            GestureDetector(
              onTap: canRedeem ? () => _redeemSlotBonus(l10n) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: canRedeem ? AppColors.gold500 : AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                child: _redeeming
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        l10n.xpRedeemButton,
                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 12, color: canRedeem ? AppColors.ink900 : AppColors.textTertiary),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kawloPlusBanner(AppLocalizations l10n) {
    return GestureDetector(
      onTap: widget.onOpenPaywall,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.star, size: 18, color: AppColors.gold500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.kawloPlusUnlimitedTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
                  Text(l10n.kawloPlusUnlimitedSubtitle, style: const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.gold500, borderRadius: BorderRadius.circular(999)),
              child: Text(l10n.kawloPlusPriceLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.ink900)),
            ),
          ],
        ),
      ),
    );
  }
}
