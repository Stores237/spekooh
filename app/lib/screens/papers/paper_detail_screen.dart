import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';

import '../../ads/rewarded_ad_controller.dart';
import '../../data/offline_papers_store.dart';
import '../../data/repositories/papers_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exam_taxonomy.dart';
import '../../models/paper_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/report_covers.dart';
import '../../widgets/spekooh_badge.dart';
import '../../widgets/spekooh_button.dart';
import '../../widgets/spekooh_banner.dart';
import 'papers_screen.dart';
import 'report_viewer_screen.dart';

/// Reports have no Subject taxonomy (subjectTitle is null/absent), so
/// without this guard the title duplicated the exam type: "Internship
/// Report, Internship Report 2022".
String _paperTitle({required String? subjectTitle, required String examTypeLabel, required int year}) {
  if (subjectTitle == null || subjectTitle == examTypeLabel) return '$examTypeLabel $year';
  return '$subjectTitle, $examTypeLabel $year';
}

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
  bool _savingOffline = false;

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
      if (mounted) {
        setState(() {
          _unlockedAmount = amount;
          // Refetch so requiresUnlock/isUnlocked reflect the payment that
          // just succeeded — without this, a just-paid gated report kept
          // showing "locked" (or a free-tier report kept hiding Save
          // offline behind the unlock hint) until the screen was reopened.
          _detail = widget.repository.getPaperDetail(paperId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.unlockFailedError('$e'))));
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _openFile(int paperId, String url) async {
    final l10n = AppLocalizations.of(context)!;
    // Prefer the offline copy when one's saved — the whole point of saving
    // for later is not needing a connection to view it again.
    final localPath = !kIsWeb ? await OfflinePapersStore.instance.absolutePathFor(paperId) : null;
    if (localPath != null) {
      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenFile)));
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenFile)));
    }
  }

  /// Reports render in-app (see ReportViewerScreen) instead of handing off
  /// to the OS's own PDF/photo app — that handoff is exactly what would let
  /// someone "view for free" and just use the OS's own Save option,
  /// defeating "free to view, paid to download" (owner decision). Exam
  /// papers keep the existing external-open behavior via _openFile.
  void _openReportViewer(String title, String fileUrl) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ReportViewerScreen(title: title, fileUrl: fileUrl)));
  }

  Future<void> _toggleOffline({required int paperId, required String title, required String subtitle, required String? fileUrl}) async {
    final l10n = AppLocalizations.of(context)!;
    final store = OfflinePapersStore.instance;
    if (store.isSaved(paperId)) {
      await store.remove(paperId);
      return;
    }
    setState(() => _savingOffline = true);
    try {
      await store.save(paperId: paperId, title: title, subtitle: subtitle, fileUrl: fileUrl);
    } on NoOfflineFileAvailableError {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noScannedFileYet)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.offlineSaveError('$e'))));
    } finally {
      if (mounted) setState(() => _savingOffline = false);
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
                  const Icon(LucideIcons.fileText, size: 40, color: AppColors.textTertiary),
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

    // Academic reports (theses, internship reports, mémoires) have no MCQ
    // questions at all, unlike exam papers' marking guides — the MCQ
    // disclaimer banner below only makes sense for the latter.
    final isReport = entry.isReport || selection?.category.key == ExamCategoryKey.reports;
    final title = selection != null
        ? _paperTitle(
            subjectTitle: selection.subject?.title,
            examTypeLabel: '${selection.examType.name}${selection.track != null ? ' ${selection.track}' : ''}',
            year: entry.year,
          )
        : _paperTitle(subjectTitle: entry.subjectTitle, examTypeLabel: entry.examTypeName ?? 'Paper', year: entry.year);
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
                  GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Padding(padding: EdgeInsets.only(top: 2), child: Icon(LucideIcons.chevronLeft))),
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
                    icon: const Icon(LucideIcons.flag, size: 20, color: AppColors.textSecondary),
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
                  // Owner decision: PhD/Master's-tier reports require payment
                  // even to view; every other report is free to view but
                  // still requires a real unlock to download — see the
                  // Download-access card below, which drives both gates
                  // through the same PaperUnlock the marking-guide flow uses.
                  final isReport = detail?.categoryKey == 'reports' || selection?.category.key == ExamCategoryKey.reports;
                  final locked = isReport && (detail?.requiresUnlock ?? false);
                  final downloadUnlocked = detail?.isUnlocked ?? false;
                  // Branded default cover art (owner-supplied) — a submitted
                  // report's file has no cover page of its own, so this is
                  // shown in its place, in both the locked and unlocked
                  // states, above the existing message/button content.
                  final reportTypeName = selection?.examType.name ?? detail?.examTypeName ?? entry.examTypeName;
                  final reportCoverAsset = isReport && reportTypeName != null ? reportCoverAssetFor(reportTypeName) : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 140),
                        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Fixed height, not the source's full ~0.707
                            // document aspect ratio — a full-bleed page
                            // reproduction at card width would balloon this
                            // card past a screen's height (same class of bug
                            // fixed elsewhere this session for the grids).
                            if (reportCoverAsset != null) SizedBox(height: 160, width: double.infinity, child: Image.asset(reportCoverAsset, fit: BoxFit.cover)),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: locked
                                    ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.lock, size: 28, color: AppColors.textSecondary),
                                  const SizedBox(height: AppSpacing.space2),
                                  Text(l10n.reportLockedTitle, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(l10n.reportLockedMessage, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              )
                            : fileUrl == null
                            ? Text(l10n.noScannedFileYet, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textTertiary))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.fileText, size: 28, color: AppColors.textSecondary),
                                  const SizedBox(height: AppSpacing.space2),
                                  SpekoohButton(
                                    size: SpekoohButtonSize.sm,
                                    onPressed: () => isReport ? _openReportViewer(title, fileUrl) : _openFile(entry.id, fileUrl),
                                    child: Text(isReport ? l10n.viewButton : l10n.openScannedPaper),
                                  ),
                                  // path_provider has no meaningful web implementation, and
                                  // web isn't the ship target (spec §6) — mobile-only.
                                  if (!kIsWeb) ...[
                                    const SizedBox(height: AppSpacing.space2),
                                    if (isReport && !downloadUnlocked)
                                      Text(l10n.unlockToDownloadHint, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textTertiary))
                                    else
                                      ListenableBuilder(
                                        listenable: OfflinePapersStore.instance,
                                        builder: (context, _) {
                                          final saved = OfflinePapersStore.instance.isSaved(entry.id);
                                          return GestureDetector(
                                            onTap: _savingOffline
                                                ? null
                                                : () => _toggleOffline(paperId: entry.id, title: title, subtitle: meta, fileUrl: fileUrl),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_savingOffline)
                                                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                                else
                                                  Icon(saved ? LucideIcons.checkCircle : LucideIcons.download, size: 14, color: saved ? AppColors.green600 : AppColors.gold700),
                                                const SizedBox(width: 6),
                                                Text(
                                                  saved ? l10n.offlineSaved : l10n.saveOffline,
                                                  style: TextStyle(
                                                    fontFamily: plusJakartaSansFamily,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: saved ? AppColors.green600 : AppColors.gold700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ],
                              ),
                              ),
                            ),
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
                        SpekoohBanner(tone: SpekoohBannerTone.blue, icon: const Icon(LucideIcons.lock), message: l10n.paywallBlockedMessage),
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
                                      Text(isReport ? l10n.reportDownloadTitle : l10n.markingGuideTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                      Text(isReport ? l10n.reportDownloadSubtitle : l10n.markingGuideSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Icon(_unlockedAmount != null || downloadUnlocked ? LucideIcons.unlock : LucideIcons.lock, size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_unlockedAmount != null)
                              Text(l10n.unlockedForAmount(_unlockedAmount!), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.green600, fontWeight: FontWeight.w600))
                            else if (downloadUnlocked)
                              Text(l10n.alreadyUnlocked, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.green600, fontWeight: FontWeight.w600))
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
              if (!isReport) ...[
                const SizedBox(height: AppSpacing.space4),
                SpekoohBanner(
                  tone: SpekoohBannerTone.blue,
                  icon: const Icon(LucideIcons.info),
                  message: l10n.mcqDisclaimer,
                ),
              ],
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
