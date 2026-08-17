import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ads/rewarded_ad_controller.dart';
import '../../data/repositories/papers_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exam_taxonomy.dart';
import '../../models/paper_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_badge.dart';
import '../../widgets/spekooh_button.dart';
import '../../widgets/spekooh_banner.dart';
import 'papers_screen.dart';

/// Ported from ui_kits/spekooh-app/PaperDetailScreen.jsx. Pushed as a
/// full-screen overlay when a paper is tapped in PapersScreen's paper list.
class PaperDetailScreen extends StatefulWidget {
  PaperDetailScreen({super.key, this.paper, this.paperEntry, PapersRepository? repository, RewardedAdController? adController})
      : repository = repository ?? RepositoryLocator.instance.papers,
        adController = adController ?? RewardedAdController.instance;

  /// Set when opened from Papers' full taxonomy drill-down — carries the
  /// resolved category/examType/subject alongside the real entry.
  final PaperSelection? paper;

  /// Set when opened from a simpler entry point (e.g. Home's featured-paper
  /// card) that only has the raw submission, not the full taxonomy chain.
  final PaperEntry? paperEntry;

  final PapersRepository repository;

  /// Drives the "Watch ad for +1 view" button shown once the daily free
  /// view limit blocks this paper (see [_viewError]). Injectable so widget
  /// tests can fake a reward without touching the real AdMob SDK.
  final RewardedAdController adController;

  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  late Future<PaperEntry?> _detail;
  bool _unlocking = false;
  int? _unlockedAmount;
  bool _viewBlocked = false;
  bool _watchingAd = false;
  final _redeemController = TextEditingController();
  bool _showRedeemField = false;

  int? get _entryId => widget.paper?.entry.id ?? widget.paperEntry?.id;

  @override
  void initState() {
    super.initState();
    final id = _entryId;
    if (id == null) {
      _detail = Future.value(null);
    } else {
      _detail = widget.repository.getPaperDetail(id).then((full) {
        _recordView(id);
        return full;
      });
    }
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  Future<void> _recordView(int paperId) async {
    try {
      await widget.repository.recordView(paperId);
      if (mounted) setState(() => _viewBlocked = false);
    } on PaywallException catch (_) {
      if (mounted) setState(() => _viewBlocked = true);
    } catch (_) {
      // View-tracking failing shouldn't block reading the detail page.
    }
  }

  Future<void> _watchAdForView(int paperId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _watchingAd = true);
    try {
      final earned = await widget.adController.showAd();
      if (!earned) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adNotCompletedError)));
        return;
      }
      await widget.repository.recordAdWatch();
      await _recordView(paperId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adLoadError('$e'))));
    } finally {
      if (mounted) setState(() => _watchingAd = false);
    }
  }

  Future<void> _unlock(int paperId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _unlocking = true);
    try {
      final amount = await widget.repository.unlockPaper(
        paperId,
        redeemCode: _redeemController.text.trim().isEmpty ? null : _redeemController.text.trim(),
      );
      if (mounted) setState(() => _unlockedAmount = amount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.unlockFailedError('$e'))));
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _openFile(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenFile)));
    }
  }

  Future<void> _openReportDialog(int paperId) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<({String reason, String details})>(
      context: context,
      builder: (context) => _ReportPaperDialog(paperId: paperId),
    );
    if (result == null || !mounted) return;
    try {
      await widget.repository.reportPaper(paperId, reason: result.reason, details: result.details);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportThanksMessage)),
        );
      }
    } on AlreadyReportedException catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.alreadyReportedMessage)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportSendError('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selection = widget.paper;
    final entry = selection?.entry ?? widget.paperEntry;
    if (entry == null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined, size: 40, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.space3),
                  Text(l10n.noPaperSelectedTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(l10n.noPaperSelectedBody,
                      textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.space4),
                  SpekoohButton(size: SpekoohButtonSize.sm, onPressed: () => Navigator.of(context).pop(), child: Text(l10n.backButton)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final title = selection != null
        ? '${selection.subject.title} — ${selection.examType.name}${selection.track != null ? ' ${selection.track}' : ''} ${entry.year}'
        : '${entry.subjectTitle ?? entry.examTypeName ?? 'Paper'} — ${entry.examTypeName ?? ''} ${entry.year}';
    final meta = selection != null
        ? [
            selection.category.title,
            if (selection.system != null) (selection.system == ExamSystem.francophone ? 'Francophone' : 'Anglophone'),
          ].join(' · ')
        : (entry.track.isNotEmpty ? entry.track : '');

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.chevron_left))),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                        Text(meta, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  SpekoohBadge(text: entry.isPublished ? l10n.publishedStatus : l10n.paperUnderReview, tone: SpekoohBadgeTone.neutral),
                  IconButton(
                    tooltip: l10n.reportTooltip,
                    icon: const Icon(Icons.flag_outlined, size: 20, color: AppColors.textSecondary),
                    onPressed: () => _openReportDialog(entry.id),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              FutureBuilder<PaperEntry?>(
                future: _detail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()));
                  }
                  final detail = snapshot.data;
                  final fileUrl = detail?.fileUrl;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: fileUrl == null
                            ? Text(l10n.noScannedFileYet, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textTertiary))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.picture_as_pdf_outlined, size: 28, color: AppColors.textSecondary),
                                  const SizedBox(height: AppSpacing.space2),
                                  SpekoohButton(size: SpekoohButtonSize.sm, onPressed: () => _openFile(fileUrl), child: Text(l10n.openScannedPaper)),
                                ],
                              ),
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      if (detail != null && detail.examBoard.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                          child: Text(l10n.examBoardLabel(detail.examBoard), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      if (_viewBlocked) ...[
                        SpekoohBanner(tone: SpekoohBannerTone.blue, icon: const Icon(Icons.lock_clock_outlined), message: l10n.paywallBlockedMessage),
                        const SizedBox(height: AppSpacing.space2),
                        // google_mobile_ads has no web implementation — this
                        // affordance only appears on mobile builds, not the
                        // flutter build web target this app is dev-tested on.
                        if (!kIsWeb)
                          SpekoohButton(
                            size: SpekoohButtonSize.sm,
                            onPressed: _watchingAd ? null : () => _watchAdForView(entry.id),
                            child: _watchingAd
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(l10n.watchAdForView),
                          ),
                        const SizedBox(height: AppSpacing.space3),
                      ],
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
                                      Text(l10n.markingGuideTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                      Text(l10n.markingGuideSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Icon(_unlockedAmount != null ? Icons.lock_open : Icons.lock_outline, size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_unlockedAmount != null)
                              Text(l10n.unlockedForAmount(_unlockedAmount!), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.green600, fontWeight: FontWeight.w600))
                            else ...[
                              Row(
                                children: [
                                  SpekoohButton(
                                    size: SpekoohButtonSize.sm,
                                    onPressed: _unlocking ? null : () => _unlock(entry.id),
                                    child: _unlocking ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.unlockButton),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => setState(() => _showRedeemField = !_showRedeemField),
                                    child: Text(l10n.haveRedeemCode, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.gold700, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                ],
                              ),
                              if (_showRedeemField) ...[
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _redeemController,
                                  decoration: InputDecoration(hintText: l10n.redeemCodeHint, isDense: true, border: const OutlineInputBorder()),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.space4),
              SpekoohBanner(
                tone: SpekoohBannerTone.blue,
                icon: const Icon(Icons.info_outline),
                message: l10n.mcqDisclaimer,
              ),
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors backend PaperFlagReason (see paperFlagReasonKeys) with real
/// localized labels — the map itself can't be a compile-time const since
/// AppLocalizations needs a BuildContext, so this is a function instead.
Map<String, String> _reasonLabels(AppLocalizations l10n) => {
      'WRONG_ANSWERS': l10n.reasonWrongAnswers,
      'POOR_QUALITY': l10n.reasonPoorQuality,
      'WRONG_SUBJECT': l10n.reasonWrongSubject,
      'DUPLICATE': l10n.reasonDuplicate,
      'COPYRIGHT': l10n.reasonCopyright,
      'OTHER': l10n.reasonOther,
    };

/// Pick a reason (mirrors backend PaperFlagReason) + optional free-text
/// details. Pops null on cancel, or the selected (reason, details) record
/// on submit.
class _ReportPaperDialog extends StatefulWidget {
  const _ReportPaperDialog({required this.paperId});
  final int paperId;

  @override
  State<_ReportPaperDialog> createState() => _ReportPaperDialogState();
}

class _ReportPaperDialogState extends State<_ReportPaperDialog> {
  String _reason = paperFlagReasonKeys.first;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasonLabels = _reasonLabels(l10n);
    return AlertDialog(
      title: Text(l10n.reportDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.reportWhatsWrong, isDense: true),
            items: reasonLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _reason = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsController,
            decoration: InputDecoration(labelText: l10n.reportDetailsOptional, isDense: true, border: const OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancelButton)),
        TextButton(
          onPressed: () => Navigator.of(context).pop((reason: _reason, details: _detailsController.text.trim())),
          child: Text(l10n.submitButton),
        ),
      ],
    );
  }
}
