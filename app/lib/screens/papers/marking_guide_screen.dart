import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../data/auth_session.dart';
import '../../data/offline_guides_store.dart';
import '../../data/offline_slots_policy.dart';
import '../../data/repositories/papers_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/marking_guide.dart';
import '../../sheets/auth_sheet.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_button.dart';
import '../../widgets/spekooh_loader.dart';

/// Renders a real published marking guide (owner request, 2026-09-11 —
/// this never existed before: the paper-detail screen only ever handled
/// *unlocking* a guide, with no screen to actually read one afterward).
/// Content shape mirrors the backend exactly — see MarkingGuide's own
/// doc comment and apps.papers.models.PublishedGuide.content.
class MarkingGuideScreen extends StatefulWidget {
  MarkingGuideScreen({
    super.key,
    required this.paperId,
    required this.paperTitle,
    PapersRepository? repository,
    ProfileRepository? profileRepository,
  })  : repository = repository ?? RepositoryLocator.instance.papers,
        profileRepository = profileRepository ?? RepositoryLocator.instance.profile;

  final int paperId;
  final String paperTitle;
  final PapersRepository repository;

  /// Used only to check isPlusSubscriber for the offline-download slots
  /// cap — see paper_detail_screen's own field of the same name/comment.
  final ProfileRepository profileRepository;

  @override
  State<MarkingGuideScreen> createState() => _MarkingGuideScreenState();
}

class _MarkingGuideScreenState extends State<MarkingGuideScreen> {
  late final Future<MarkingGuide> _future = widget.repository.getMarkingGuide(widget.paperId);
  bool _saving = false;

  /// Toggle, auth gate, and cap check all mirror paper_detail_screen's own
  /// _toggleOffline exactly — same product decisions apply here (owner
  /// request, 2026-09-11): a real account is required, and a free
  /// account's saved-corrections count is capped independently of its
  /// saved-papers count (see confirmOfflineSlotAvailable's own comment).
  Future<void> _toggleOffline(MarkingGuide guide) async {
    final store = OfflineGuidesStore.instance;
    if (store.isSaved(widget.paperId)) {
      await store.remove(widget.paperId);
      return;
    }
    if (!AuthSession.instance.isLoggedIn) {
      final loggedIn = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AuthSheet(),
      );
      if (loggedIn != true || !mounted) return;
    }
    final canSave = await confirmOfflineSlotAvailable(
      context,
      currentCount: store.guides.length,
      profileRepository: widget.profileRepository,
      errorMessage: (l10n) => l10n.offlineSlotsFullGuidesError(kMaxOfflineSlots),
    );
    if (!canSave || !mounted) return;
    setState(() => _saving = true);
    await store.save(paperId: widget.paperId, title: widget.paperTitle, guide: guide);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Padding(
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
                        Text(l10n.markingGuideTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
                        Text(widget.paperTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Expanded(
                child: FutureBuilder<MarkingGuide>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: SpekoohLoader());
                    }
                    if (snapshot.hasError) {
                      return _errorState(l10n, snapshot.error!);
                    }
                    return _content(l10n, snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(AppLocalizations l10n, Object error) {
    final message = switch (error) {
      GuideNotPublishedException() => l10n.markingGuideNotYetAvailable,
      GuideLockedException() => l10n.markingGuideLockedError,
      _ => apiErrorDetail(error) ?? l10n.markingGuideNotYetAvailable,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(LucideIcons.clock, size: 32, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _content(AppLocalizations l10n, MarkingGuide guide) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListenableBuilder(
            listenable: OfflineGuidesStore.instance,
            builder: (context, _) {
              final saved = OfflineGuidesStore.instance.isSaved(widget.paperId);
              return SizedBox(
                width: double.infinity,
                child: SpekoohButton(
                  variant: SpekoohButtonVariant.outline,
                  onPressed: _saving ? null : () => _toggleOffline(guide),
                  child: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(saved ? l10n.offlineSaved : l10n.saveOffline),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space4),
          if (guide.mcqAnswers.isNotEmpty) ...[
            Text(l10n.markingGuideMcqSectionTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.space3),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in guide.mcqAnswers.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space5),
          ],
          if (guide.nonMcqQuestions.isNotEmpty) ...[
            Text(l10n.markingGuideWrittenSectionTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.space3),
            for (final q in guide.nonMcqQuestions) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.text, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(q.answer, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],
          ],
          const SizedBox(height: AppSpacing.space5),
        ],
      ),
    );
  }
}
