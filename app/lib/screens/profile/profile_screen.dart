import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/auth_session.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repository_locator.dart';
import '../../models/achievement.dart';
import '../../models/spekooh_user.dart';
import '../../models/submission.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_badge.dart';
import '../../widgets/spekooh_button.dart';
import '../common/circular_back_button.dart';

/// Ported from ui_kits/spekooh-app/ProfileScreen.jsx.
class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key, ProfileRepository? repository, this.onOpenSettings, this.onLogin})
      : repository = repository ?? RepositoryLocator.instance.profile;

  final ProfileRepository repository;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onLogin;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // `late` defers evaluation to first access — guarded by _isLoggedIn in
  // build() below, so a guest never actually fires these (all three need
  // auth: /auth/me/, /credits/..., /papers/submissions/?submitted_by=me).
  late final Future<SpekoohUser> _userFuture = widget.repository.getUser();
  late final Future<List<Achievement>> _achievementsFuture = widget.repository.getAchievements();
  late final Future<List<Submission>> _submissionsFuture = widget.repository.getSubmissions();

  bool get _isLoggedIn => AuthSession.instance.isLoggedIn;

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
                  Row(
                    children: [
                      CircularBackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: AppSpacing.space3),
                      Text('Profile', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                    ],
                  ),
                  CircularBackButton(onTap: () => widget.onOpenSettings?.call()),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              if (!_isLoggedIn) _signedOutPrompt() else ...[
              FutureBuilder<SpekoohUser>(
                future: _userFuture,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold200),
                              alignment: Alignment.center,
                              child: Text(user.name[0], style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.gold700)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                                  Text(user.joinDate, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      SpekoohBadge(text: '${user.submissionsCount} submissions', tone: SpekoohBadgeTone.blue),
                                      const SizedBox(width: 8),
                                      SpekoohBadge(text: '${user.quizzesCount} quizzes', tone: SpekoohBadgeTone.amber),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space5),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BONUS CREDIT BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 28, color: AppColors.white),
                                children: [
                                  TextSpan(text: '${user.creditBalance} '),
                                  const TextSpan(text: 'pts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${user.submissionsCount} papers submitted · redeem code value scales with your contributions',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.redeemCode.isEmpty ? 'No active redeem code' : 'Redeem code ready',
                                          style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                      Text(
                                        user.redeemCode.isEmpty
                                            ? 'You\'ll get one once a verified submission earns a bonus tier.'
                                            : user.redeemCodeSubtitle,
                                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.confirmation_number_outlined),
                              ],
                            ),
                            if (user.redeemCode.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSunken,
                                  border: Border.all(color: AppColors.borderSubtle),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(user.redeemCode, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 1, color: AppColors.textPrimary)),
                                    GestureDetector(
                                      onTap: () => Share.share(
                                        'Use my Spekooh redeem code ${user.redeemCode} — ${user.redeemCodeSubtitle}',
                                        subject: 'Spekooh redeem code',
                                      ),
                                      child: Text('Share', style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.gold700, fontWeight: FontWeight.w700, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              _sectionLabel('Badges'),
              FutureBuilder<List<Achievement>>(
                future: _achievementsFuture,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const [];
                  return GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                    children: items
                        .map((a) => Container(
                              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                              child: Opacity(
                                opacity: a.earned ? 1 : 0.45,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(a.icon, size: 20, color: AppColors.gold600),
                                    const SizedBox(height: 6),
                                    Text(a.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              _sectionLabel('Submission status'),
              FutureBuilder<List<Submission>>(
                future: _submissionsFuture,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const [];
                  return Container(
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(items[i].title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                      Text(items[i].date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                SpekoohBadge(text: items[i].status, tone: items[i].tone),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              ],
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space5, bottom: AppSpacing.space2),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
      );

  // A guest reaching this screen has no account to show — submissions,
  // credit balance, badges, and redeem codes are all per-account concepts.
  // Every underlying repository call needs auth (/auth/me/, /credits/...,
  // /papers/submissions/?submitted_by=me), so this avoids firing requests
  // guaranteed to 401 and shows an honest prompt instead.
  Widget _signedOutPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.person_outline, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text('Log in to see your profile', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Your submissions, credit balance, and badges show up here once you have an account.',
              textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.space4),
          SpekoohButton(onPressed: widget.onLogin, child: const Text('Log in')),
        ],
      ),
    );
  }
}
