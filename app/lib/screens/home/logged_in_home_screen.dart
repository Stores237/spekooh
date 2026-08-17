import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/quizzes_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz.dart';
import '../../models/spekooh_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_button.dart';

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
                  final initial = (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '·';
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
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold200),
                                        alignment: Alignment.center,
                                        child: Text(initial, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, color: AppColors.gold700)),
                                      ),
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
                                        const Icon(Icons.local_fire_department, size: 12, color: AppColors.ink900),
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
                                child: const Icon(Icons.track_changes_outlined, size: 20, color: AppColors.green500),
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
                              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
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
                                      child: const Icon(Icons.check, size: 12, color: AppColors.gold700),
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
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.5,
                        children: [
                          _quickAction(Icons.description_outlined, l10n.navPapers, onOpenPapers),
                          _quickAction(Icons.menu_book_outlined, l10n.notesTitle, onOpenNotes),
                          _quickAction(Icons.upload_outlined, l10n.quickActionContribute, onOpenSubmit),
                          _quickAction(Icons.shopping_bag_outlined, l10n.shopTitle, onOpenShop),
                          _quickAction(Icons.chat_bubble_outline, l10n.navForum, onOpenForum),
                          _quickAction(Icons.bolt_outlined, l10n.navQuizzes, onOpenQuizzes),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -4),
                      child: FutureBuilder<Quiz>(
                        future: quizzesRepository.getDailyChallenge(),
                        builder: (context, snapshot) {
                          final quiz = snapshot.data;
                          return GestureDetector(
                            onTap: onOpenQuizzes,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(18)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.dailyChallengeLabel, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text(
                                          quiz == null ? l10n.dailyChallengeLoading : l10n.dailyChallengeInfo(quiz.title, quiz.questionCount),
                                          style: const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 11),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(color: AppColors.gold500, borderRadius: BorderRadius.circular(999)),
                                          child: Text(l10n.playNow, style: const TextStyle(color: AppColors.ink900, fontWeight: FontWeight.w800, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.15)),
                                  FutureBuilder<({int currentStreak, bool playedToday})>(
                                    future: quizzesRepository.getStreak(),
                                    builder: (context, streakSnapshot) {
                                      final streak = streakSnapshot.data?.currentStreak ?? 0;
                                      return Expanded(
                                        child: Column(
                                          children: [
                                            Icon(Icons.local_fire_department_outlined, size: 22, color: AppColors.gold500),
                                            const SizedBox(height: 4),
                                            Text(streak > 0 ? l10n.streakDaysCount(streak) : l10n.streakStart, style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                            Text(streak > 0 ? l10n.streakKeepGoing : l10n.streakPlayToBegin, style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 10)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
