import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/achievement_definitions.dart';
import '../../data/auth_session.dart';
import '../../data/repositories/papers_repository.dart' show SubmissionFile;
import '../../data/repositories/profile_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/achievement.dart';
import '../../models/spekooh_user.dart';
import '../../models/submission.dart';
import '../../sheets/achievements_sheet.dart';
import '../../sheets/edit_profile_sheet.dart';
import '../../shell/route_observers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/spekooh_badge.dart';
import '../../widgets/spekooh_button.dart';
import '../common/circular_back_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ported from ui_kits/spekooh-app/ProfileScreen.jsx.
class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key, ProfileRepository? repository, this.onOpenSettings, this.onLogin, this.onOpenPaywall})
      : repository = repository ?? RepositoryLocator.instance.profile;

  final ProfileRepository repository;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onLogin;

  /// Settings already has a "Spekooh Pro" upsell row leading here — this is
  /// a second, more visible entry point on Profile itself (owner decision,
  /// 2026-08-28, adapting a reference promo card), same real paywall/price,
  /// not a separate offer.
  final VoidCallback? onOpenPaywall;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  // `late` defers evaluation to first access — guarded by _isLoggedIn in
  // build() below, so a guest never actually fires these (all three need
  // auth: /auth/me/, /credits/..., /papers/submissions/?submitted_by=me).
  // Not `final`: _refresh below re-assigns all three so the card reflects
  // real, current counts — after a real profile edit, and after returning
  // to an already-open Profile from a screen pushed on top of it (see
  // didPopNext) — without a full screen reopen.
  late Future<SpekoohUser> _userFuture = widget.repository.getUser();
  late Future<List<Achievement>> _achievementsFuture = _userFuture.then(widget.repository.getAchievements);
  late Future<List<Submission>> _submissionsFuture = widget.repository.getSubmissions();

  // The avatar Container used to be a plain, non-interactive initial-letter
  // circle — tapping it did nothing. Overlays the freshly-uploaded URL on
  // top of whatever _userFuture resolved to, rather than refetching the
  // whole profile just to pick up one changed field.
  String? _avatarUrlOverride;
  bool _isUploadingAvatar = false;

  bool get _isLoggedIn => AuthSession.instance.isLoggedIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) profileRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    profileRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // A real, published contribution's count previously stayed 0 on an
  // already-open Profile screen popped back into from a screen pushed on
  // top of it (e.g. Settings) — Profile itself always refetches fine on a
  // fresh push, but returning to this same still-alive instance via pop
  // never did (found from a live report, 2026-08-28). RouteAware fixes
  // that: refetch whenever this becomes the visible route again.
  @override
  void didPopNext() => _refresh();

  void _refresh() {
    if (!_isLoggedIn) return;
    setState(() {
      _userFuture = widget.repository.getUser();
      _achievementsFuture = _userFuture.then(widget.repository.getAchievements);
      _submissionsFuture = widget.repository.getSubmissions();
    });
  }

  Future<void> _openEditProfile(SpekoohUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final emailChanged = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(user: user, repository: widget.repository),
    );
    if (emailChanged == null || !mounted) return;
    _refresh();
    if (emailChanged) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.editProfileEmailChangedNotice)));
    }
  }

  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final xfile = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (xfile == null || !mounted) return;

    final bytes = await xfile.readAsBytes();
    setState(() => _isUploadingAvatar = true);
    try {
      final avatarUrl = await widget.repository.updateAvatar(
        SubmissionFile(bytes: bytes, fileName: xfile.name, mimeType: xfile.mimeType ?? 'image/jpeg'),
      );
      if (mounted) setState(() => _avatarUrlOverride = avatarUrl);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.avatarUploadError)));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircularBackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: AppSpacing.space3),
                      Text(l10n.profileTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                    ],
                  ),
                  CircularBackButton(icon: LucideIcons.settings, onTap: () => widget.onOpenSettings?.call()),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              if (!_isLoggedIn) _signedOutPrompt(l10n) else ...[
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
                            GestureDetector(
                              onTap: _isUploadingAvatar ? null : _pickAvatar,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold200),
                                alignment: Alignment.center,
                                clipBehavior: Clip.antiAlias,
                                child: _isUploadingAvatar
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : (_avatarUrlOverride ?? user.avatarUrl) != null
                                        ? ClipOval(
                                            child: Image.network(
                                              (_avatarUrlOverride ?? user.avatarUrl)!,
                                              width: 52,
                                              height: 52,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Text(
                                                user.name[0],
                                                style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.gold700),
                                              ),
                                            ),
                                          )
                                        : Text(user.name[0], style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.gold700)),
                              ),
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
                                      SpekoohBadge(text: l10n.submissionsCountBadge(user.submissionsCount), tone: SpekoohBadgeTone.blue),
                                      const SizedBox(width: 8),
                                      SpekoohBadge(text: l10n.quizzesCountBadge(user.quizzesCount), tone: SpekoohBadgeTone.amber),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openEditProfile(user),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(LucideIcons.pencil, size: 18, color: AppColors.textTertiary),
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
                            Text(l10n.bonusCreditBalanceLabel, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 28, color: AppColors.white),
                                children: [
                                  TextSpan(text: '${user.creditBalance} '),
                                  TextSpan(text: l10n.ptsLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.submissionsScaleNote(user.submissionsCount),
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
                                      Text(user.redeemCode.isEmpty ? l10n.redeemCodeNotActive : l10n.redeemCodeReady,
                                          style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                      Text(
                                        user.redeemCode.isEmpty
                                            ? l10n.redeemCodeEarnHint
                                            : user.redeemCodeSubtitle,
                                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(LucideIcons.ticket),
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
                                        l10n.shareRedeemCodeMessage(user.redeemCode, user.redeemCodeSubtitle),
                                        subject: l10n.shareRedeemCodeSubject,
                                      ),
                                      child: Text(l10n.shareLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.gold700, fontWeight: FontWeight.w700, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (user.referralCode.isNotEmpty) ...[
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
                                        Text(l10n.inviteAFriendTitle,
                                            style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                        Text(
                                          l10n.inviteAFriendSubtitle,
                                          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(LucideIcons.userPlus),
                                ],
                              ),
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
                                    Text(user.referralCode, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 1, color: AppColors.textPrimary)),
                                    GestureDetector(
                                      onTap: () => Share.share(
                                        l10n.shareReferralMessage(user.referralCode),
                                        subject: l10n.shareReferralSubject,
                                      ),
                                      child: Text(l10n.shareLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.gold700, fontWeight: FontWeight.w700, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space5, bottom: AppSpacing.space2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.badgesSectionLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
                    GestureDetector(
                      onTap: () async {
                        final items = await _achievementsFuture;
                        if (context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AchievementsSheet(items: items),
                          );
                        }
                      },
                      child: Text(
                        l10n.badgesSectionCount(achievementDefinitions.length),
                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold700),
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<Achievement>>(
                future: _achievementsFuture,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const [];
                  return GridView.count(
                    crossAxisCount: responsiveCrossAxisCount(context, 4),
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
              const SizedBox(height: AppSpacing.space4),
              InkWell(
                onTap: widget.onOpenPaywall,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.star, size: 20, color: AppColors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.spekoohProTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.white)),
                            Text(l10n.spekoohProSubtitle, style: const TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: Colors.white70),
                    ],
                  ),
                ),
              ),
              _sectionLabel(l10n.submissionStatusSectionLabel),
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
  Widget _signedOutPrompt(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(LucideIcons.user, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(l10n.profileLoginPrompt, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(l10n.profileLoginPromptSubtitle,
              textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.space4),
          SpekoohButton(onPressed: widget.onLogin, child: Text(l10n.logIn)),
        ],
      ),
    );
  }
}
