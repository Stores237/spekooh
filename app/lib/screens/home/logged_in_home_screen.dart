import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/auth_session.dart';
import '../../data/locale_controller.dart';
import '../../data/offline_papers_store.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/quizzes_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/offline_paper.dart';
import '../../models/quiz.dart';
import '../../models/spekooh_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/spekooh_button.dart';
import '../../widgets/user_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';

/// Ported from ui_kits/spekooh-app/LoggedInHomeScreen.jsx.
class LoggedInHomeScreen extends StatelessWidget {
  LoggedInHomeScreen({
    super.key,
    this.onOpenSettings,
    this.onOpenPapers,
    this.onOpenSubmit,
    this.onOpenForum,
    this.onOpenQuizzes,
    this.onOpenNotifications,
    this.onOpenProfile,
    this.onOpenNotes,
    this.onOpenShop,
    this.onOpenPaywall,
    ProfileRepository? profileRepository,
    QuizzesRepository? quizzesRepository,
  })  : profileRepository = profileRepository ?? RepositoryLocator.instance.profile,
        quizzesRepository = quizzesRepository ?? RepositoryLocator.instance.quizzes;

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenPapers;
  final VoidCallback? onOpenSubmit;
  final VoidCallback? onOpenForum;
  final VoidCallback? onOpenQuizzes;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenPaywall;
  final ProfileRepository profileRepository;
  final QuizzesRepository quizzesRepository;

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              FutureBuilder<SpekoohUser>(
                future: profileRepository.getUser(),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return FutureBuilder<({int currentStreak, bool playedToday})>(
                    future: quizzesRepository.getStreak(),
                    builder: (context, streakSnapshot) {
                      final streak = streakSnapshot.data?.currentStreak ?? 0;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPad, AppSpacing.space4, AppSpacing.screenPad, 40),
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
                                      // Owner-reported (2026-09-03): a real,
                                      // set-and-visible-on-Profile avatar
                                      // never showed here — this was its own
                                      // separate copy that only ever
                                      // rendered the initial letter, never
                                      // checking avatarUrl at all.
                                      UserAvatar(name: user?.name ?? '', avatarUrl: user?.avatarUrl, size: 38),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_greeting(l10n), style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12)),
                                          Text(user?.name ?? '…', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.white)),
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
                                          _langPill('EN', 'en'),
                                          _langPill('FR', 'fr'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _darkIconButton(LucideIcons.settings, onOpenSettings),
                                    const SizedBox(width: 8),
                                    _darkIconButton(LucideIcons.bell, onOpenNotifications),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.space4),
                            GestureDetector(
                              onTap: onOpenQuizzes,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.gold500, borderRadius: BorderRadius.circular(999)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.flame, size: 12, color: AppColors.ink900),
                                        const SizedBox(width: 4),
                                        Text(
                                          streak > 0 ? l10n.streakDayCount(streak) : l10n.startAStreak,
                                          style: const TextStyle(color: AppColors.ink900, fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -24),
                      child: InkWell(
                        onTap: onOpenPapers,
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
                                child: const Icon(LucideIcons.target, size: 20, color: AppColors.green500),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.practiceModeLabel, style: TextStyle(color: AppColors.green600, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                                    Text(l10n.practiceModeTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                                    Text(l10n.practiceModeSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: FutureBuilder<SpekoohUser>(
                        future: profileRepository.getUser(),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          if (user == null || user.trialDaysRemaining <= 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.trialLabel, style: TextStyle(color: AppColors.gold700, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
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
                                      child: const Icon(LucideIcons.check, size: 12, color: AppColors.gold700),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        user.firstUnlockFreeEligible ? l10n.trialFirstUnlockFree : l10n.trialUnlimitedViews,
                                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                                      child: Text(l10n.trialDaysLeft(user.trialDaysRemaining), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.trialFeatures, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 10),
                                SizedBox(width: double.infinity, child: SpekoohButton(onPressed: onOpenPaywall, child: Text(l10n.trialKeepAccess))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: GridView.count(
                        crossAxisCount: responsiveCrossAxisCount(context, 3),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        // Taller-than-wide before (icon over label, 2 lines);
                        // icon-and-label now sit on one line (owner decision,
                        // 2026-08-28), so each card needs far less height.
                        childAspectRatio: 2.6,
                        children: [
                          _quickAction(LucideIcons.fileText, l10n.navPapers, onOpenPapers, IconChipTint.blue),
                          _quickAction(LucideIcons.bookOpen, l10n.notesTitle, onOpenNotes, IconChipTint.purple),
                          _quickAction(LucideIcons.upload, l10n.quickActionContribute, onOpenSubmit, IconChipTint.gold),
                          _quickAction(LucideIcons.shoppingBag, l10n.shopTitle, onOpenShop, IconChipTint.green),
                          _quickAction(LucideIcons.messageCircle, l10n.navForum, onOpenForum, IconChipTint.red),
                          _quickAction(LucideIcons.zap, l10n.navQuizzes, onOpenQuizzes, IconChipTint.amber),
                        ],
                      ),
                    ),
                    // Two separate cards (owner decision, 2026-08-28, adapting a
                    // reference design) instead of one dark card split by an
                    // internal divider — same real data as before (quiz.title,
                    // quiz.questionCount, the real quiz.suggestedTime, and the
                    // real streak from quizzesRepository.getStreak()), just
                    // restyled. IntrinsicHeight lets CrossAxisAlignment.stretch
                    // make both cards match height even though their content
                    // differs — without it, Expanded inside a Row that's
                    // itself height-unconstrained (this Column sits inside a
                    // SingleChildScrollView) throws at layout time.
                    Transform.translate(
                      offset: const Offset(0, -4),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: FutureBuilder<Quiz>(
                                future: quizzesRepository.getDailyChallenge(),
                                builder: (context, snapshot) {
                                  final quiz = snapshot.data;
                                  return GestureDetector(
                                    onTap: onOpenQuizzes,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                l10n.dailyChallengeLabel.toUpperCase(),
                                                style: const TextStyle(color: AppColors.gold700, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                                              ),
                                              if (quiz != null) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: AppColors.gold50, borderRadius: BorderRadius.circular(999)),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(LucideIcons.clock, size: 10, color: AppColors.gold700),
                                                      const SizedBox(width: 3),
                                                      Text(quiz.suggestedTime, style: const TextStyle(color: AppColors.gold700, fontWeight: FontWeight.w800, fontSize: 10)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            quiz == null ? l10n.dailyChallengeLoading : quiz.title,
                                            style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (quiz != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              l10n.dailyChallengeInfo(quiz.title, quiz.questionCount),
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(999)),
                                            alignment: Alignment.center,
                                            child: Text(l10n.playNow, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: FutureBuilder<({int currentStreak, bool playedToday})>(
                                future: quizzesRepository.getStreak(),
                                builder: (context, streakSnapshot) {
                                  final streak = streakSnapshot.data?.currentStreak ?? 0;
                                  return GestureDetector(
                                    onTap: onOpenQuizzes,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold200, width: 3)),
                                            alignment: Alignment.center,
                                            child: const Icon(LucideIcons.flame, size: 20, color: AppColors.gold600),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            streak > 0 ? l10n.streakDaysCount(streak) : l10n.streakStart,
                                            style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            streak > 0 ? l10n.streakKeepGoing : l10n.streakPlayToBegin,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Empty when nothing's been saved offline yet (or on
                    // web, where OfflinePapersStore never bootstraps —
                    // path_provider has no meaningful web implementation
                    // and this isn't the ship target, spec §6) — no
                    // section at all rather than an empty-state card, since
                    // this is a bonus surface for something saved
                    // elsewhere (PaperDetailScreen), not a primary flow.
                    ListenableBuilder(
                      listenable: OfflinePapersStore.instance,
                      builder: (context, _) {
                        final saved = OfflinePapersStore.instance.papers;
                        if (saved.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.space2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(l10n.readyOfflineTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                                  Text(l10n.offlineDownloadsCount(saved.length), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold700)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.space2),
                              for (final paper in saved) ...[
                                InkWell(
                                  onTap: () => _openOfflinePaper(context, paper),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(12)),
                                          alignment: Alignment.center,
                                          child: const Icon(LucideIcons.download, size: 18, color: AppColors.green600),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(paper.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                              Text(l10n.offlineReadyTag, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.green600, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.space2),
                              ],
                            ],
                          ),
                        );
                      },
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

  Future<void> _openOfflinePaper(BuildContext context, OfflinePaper paper) async {
    final l10n = AppLocalizations.of(context)!;
    final path = await OfflinePapersStore.instance.absolutePathFor(paper.paperId);
    if (path == null) return;
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenFile)));
    }
  }

  /// Same switch as Settings' language row (SettingsScreen._changeLanguage)
  /// — this header pill used to be purely decorative (no onTap at all), so
  /// tapping it did nothing. LocaleController.instance is a ChangeNotifier
  /// that SpekoohApp's root listens to, so calling setLocale here rebuilds
  /// the whole app (including this pill's own highlight) with no local
  /// state needed, despite this being a StatelessWidget.
  Future<void> _changeLanguage(String code) async {
    await LocaleController.instance.setLocale(code);
    if (AuthSession.instance.isLoggedIn) {
      unawaited(profileRepository.setLanguagePreference(code).catchError((_) {}));
    }
  }

  Widget _langPill(String label, String code) {
    final active = LocaleController.instance.locale.languageCode == code;
    return GestureDetector(
      onTap: active ? null : () => _changeLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: active ? AppColors.white : null, borderRadius: BorderRadius.circular(999)),
        child: Text(
          label,
          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w800, color: active ? AppColors.ink900 : AppColors.white),
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

  // Icon and label used to stack (2 lines, one uniform gold icon color for
  // all 6 cards) — now a single line with a distinct tint per card, using
  // the same IconChip tint system the rest of the app already uses for
  // categorical color (owner decision, 2026-08-28, found from a live
  // screenshot).
  Widget _quickAction(IconData icon, String label, VoidCallback? onTap, IconChipTint tint) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconChip(icon: icon, tint: tint, size: 30),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
