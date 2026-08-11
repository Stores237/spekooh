import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/papers_repository.dart';
import '../../data/repository_locator.dart';
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
  PaperDetailScreen({super.key, this.paper, this.paperEntry, PapersRepository? repository})
      : repository = repository ?? RepositoryLocator.instance.papers;

  /// Set when opened from Papers' full taxonomy drill-down — carries the
  /// resolved category/examType/subject alongside the real entry.
  final PaperSelection? paper;

  /// Set when opened from a simpler entry point (e.g. Home's featured-paper
  /// card) that only has the raw submission, not the full taxonomy chain.
  final PaperEntry? paperEntry;

  final PapersRepository repository;

  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  late Future<PaperEntry?> _detail;
  bool _unlocking = false;
  int? _unlockedAmount;
  String? _viewError;
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
    } on PaywallException catch (e) {
      if (mounted) setState(() => _viewError = e.message);
    } catch (_) {
      // View-tracking failing shouldn't block reading the detail page.
    }
  }

  Future<void> _unlock(int paperId) async {
    setState(() => _unlocking = true);
    try {
      final amount = await widget.repository.unlockPaper(
        paperId,
        redeemCode: _redeemController.text.trim().isEmpty ? null : _redeemController.text.trim(),
      );
      if (mounted) setState(() => _unlockedAmount = amount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unlock failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the file.')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('No paper selected', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Browse the Papers tab and pick a subject to open a real paper.',
                      textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.space4),
                  SpekoohButton(size: SpekoohButtonSize.sm, onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
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
                  SpekoohBadge(text: entry.isPublished ? 'Published' : 'Under review', tone: SpekoohBadgeTone.neutral),
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
                            ? Text('No scanned file on this submission yet.', textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textTertiary))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.picture_as_pdf_outlined, size: 28, color: AppColors.textSecondary),
                                  const SizedBox(height: AppSpacing.space2),
                                  SpekoohButton(size: SpekoohButtonSize.sm, onPressed: () => _openFile(fileUrl), child: const Text('Open scanned paper')),
                                ],
                              ),
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      if (detail != null && detail.examBoard.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                          child: Text('Exam board: ${detail.examBoard}', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      if (_viewError != null) ...[
                        SpekoohBanner(tone: SpekoohBannerTone.blue, icon: const Icon(Icons.lock_clock_outlined), message: _viewError!),
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
                                      Text('Marking guide', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                      Text('Instructor-authored + in-house MCQ key', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Icon(_unlockedAmount != null ? Icons.lock_open : Icons.lock_outline, size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_unlockedAmount != null)
                              Text('Unlocked for $_unlockedAmount FCFA.', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.green600, fontWeight: FontWeight.w600))
                            else ...[
                              Row(
                                children: [
                                  SpekoohButton(
                                    size: SpekoohButtonSize.sm,
                                    onPressed: _unlocking ? null : () => _unlock(entry.id),
                                    child: _unlocking ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Unlock — 500 FCFA'),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => setState(() => _showRedeemField = !_showRedeemField),
                                    child: Text('Have a redeem code?', style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.gold700, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                ],
                              ),
                              if (_showRedeemField) ...[
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _redeemController,
                                  decoration: const InputDecoration(hintText: 'Redeem code', isDense: true, border: OutlineInputBorder()),
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
                message: 'Objective/MCQ answers are marked in-house by the Spekooh review team, not the instructor.',
              ),
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }
}
