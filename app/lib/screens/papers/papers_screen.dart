import 'package:flutter/material.dart';
import '../../data/repositories/papers_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exam_taxonomy.dart';
import '../../models/paper_entry.dart';
import '../../models/subject.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/search_input.dart';
import '../../widgets/spekooh_badge.dart';
import '../../widgets/subject_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A fully-resolved paper selection (subject + exam type + the real,
/// already-submitted [PaperEntry]), handed to `onOpenPaper` when the user
/// taps a paper in the paper list.
class PaperSelection {
  const PaperSelection({
    required this.category,
    required this.system,
    required this.examType,
    required this.track,
    required this.subject,
    required this.entry,
  });

  final ExamCategory category;
  final ExamSystem? system;
  final ExamType examType;
  final String? track;
  final Subject subject;
  final PaperEntry entry;
}

/// Ported from ui_kits/spekooh-app/PapersScreen.jsx — the most complex
/// screen: a multi-step drill-down (category -> system -> examType ->
/// track -> subject -> paper-by-year list). State is one immutable
/// `PaperBrowseSelection` (see models/exam_taxonomy.dart); the current step
/// is a pure function of what's selected, never tracked separately. One of
/// the 5 bottom tabs.
class PapersScreen extends StatefulWidget {
  PapersScreen({super.key, PapersRepository? repository, this.onOpenPaper})
      : repository = repository ?? RepositoryLocator.instance.papers;

  final PapersRepository repository;
  final ValueChanged<PaperSelection>? onOpenPaper;

  @override
  State<PapersScreen> createState() => _PapersScreenState();
}

class _PapersScreenState extends State<PapersScreen> {
  PaperBrowseSelection _selection = const PaperBrowseSelection();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(PaperBrowseSelection Function() next) => setState(() {
        _selection = next();
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: switch (_selection.currentStep) {
            PaperBrowseStep.category => _categoryStep(l10n),
            PaperBrowseStep.system => _systemStep(l10n),
            PaperBrowseStep.examType => _examTypeStep(l10n),
            PaperBrowseStep.track => _trackStep(l10n),
            PaperBrowseStep.subject => _subjectStep(l10n),
            PaperBrowseStep.paperList => _paperListStep(l10n),
          },
        ),
      ),
    );
  }

  Widget _backHeader(String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _select(() => _selection.stepBack()),
          child: const Padding(padding: EdgeInsets.only(top: 2), child: Icon(LucideIcons.chevronLeft)),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
              if (subtitle != null) Text(subtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  // Step 1: category grid.
  Widget _categoryStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          Text(l10n.papersTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(l10n.papersSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.space4),
          SearchInput(placeholder: l10n.searchExamOrSubject, controller: _searchController),
          const SizedBox(height: AppSpacing.space5),
          Text(l10n.categoryLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
          const SizedBox(height: AppSpacing.space3),
          FutureBuilder<List<ExamCategory>>(
            future: widget.repository.getCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const [];
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.space3,
                mainAxisSpacing: AppSpacing.space3,
                childAspectRatio: 1.15,
                children: categories
                    .map((c) => SubjectCard(
                          icon: IconChip(icon: c.icon, tint: c.tint),
                          title: c.title,
                          subtitle: c.subtitle,
                          onTap: () => _select(() => _selection.selectCategory(c)),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  // Step 2: system (only for categories that require one).
  Widget _systemStep(AppLocalizations l10n) {
    final category = _selection.category!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          _backHeader(l10n.chooseSystemHeader(category.title)),
          const SizedBox(height: AppSpacing.space4),
          _optionRow(
            'Francophone',
            category.key == ExamCategoryKey.university ? 'Examen Semestre · Rattrapage' : 'BEPC · Probatoire · Baccalauréat',
            () => _select(() => _selection.selectSystem(ExamSystem.francophone)),
          ),
          const SizedBox(height: AppSpacing.space3),
          _optionRow(
            'Anglophone',
            category.key == ExamCategoryKey.university ? 'Semester Exam · Resit' : 'O Level · A Level',
            () => _select(() => _selection.selectSystem(ExamSystem.anglophone)),
          ),
        ],
      ),
    );
  }

  // Step 3: exam type grid.
  Widget _examTypeStep(AppLocalizations l10n) {
    final category = _selection.category!;
    final header = category.requiresSystem
        ? l10n.examTypeStepHeaderWithSystem(category.title, _selection.system == ExamSystem.francophone ? 'Francophone' : 'Anglophone')
        : category.title;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          _backHeader(header),
          const SizedBox(height: AppSpacing.space3),
          SearchInput(placeholder: l10n.searchExamType),
          const SizedBox(height: AppSpacing.space4),
          FutureBuilder<List<ExamType>>(
            future: widget.repository.getExamTypes(category.key, _selection.system),
            builder: (context, snapshot) {
              final examTypes = snapshot.data ?? const [];
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.space3,
                mainAxisSpacing: AppSpacing.space3,
                childAspectRatio: 1.3,
                children: examTypes
                    .map((t) => InkWell(
                          onTap: () => _select(() => _selection.selectExamType(t)),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SpekoohBadge(text: t.mockVariantLabel != null ? l10n.examTypeOfficialPlus(t.mockVariantLabel!) : l10n.examTypeOfficialOnly, tone: t.badgeTone),
                                const SizedBox(height: 6),
                                Text(t.name, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                Text(t.subtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Step 4: track (only for exam types that require one).
  Widget _trackStep(AppLocalizations l10n) {
    final examType = _selection.examType!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          _backHeader(l10n.chooseTrackHeader(examType.name)),
          const SizedBox(height: AppSpacing.space4),
          for (final track in examType.tracks!) ...[
            _optionRow(track, null, () => _select(() => _selection.selectTrack(track))),
            const SizedBox(height: AppSpacing.space3),
          ],
        ],
      ),
    );
  }

  // Step 5: subject grid.
  Widget _subjectStep(AppLocalizations l10n) {
    final examType = _selection.examType!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          _backHeader(examType.name, subtitle: _selection.track),
          const SizedBox(height: AppSpacing.space3),
          SearchInput(placeholder: l10n.searchSubjects),
          const SizedBox(height: AppSpacing.space4),
          FutureBuilder<List<Subject>>(
            future: widget.repository.getSubjects(examType.name),
            builder: (context, snapshot) {
              final subjects = snapshot.data ?? const [];
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.space3,
                mainAxisSpacing: AppSpacing.space3,
                childAspectRatio: 1.15,
                children: subjects
                    .map((s) => SubjectCard(
                          icon: IconChip(icon: s.icon, tint: s.tint),
                          title: s.title,
                          subtitle: l10n.subjectCardSubtitle,
                          badgeText: l10n.navPapers,
                          code: s.code,
                          onTap: () => _select(() => _selection.selectSubject(s.key)),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Step 6: real submitted papers for the resolved subject.
  Widget _paperListStep(AppLocalizations l10n) {
    final examType = _selection.examType!;

    return FutureBuilder<List<Subject>>(
      future: widget.repository.getSubjects(examType.name),
      builder: (context, subjectSnapshot) {
        final subject =
            (subjectSnapshot.data ?? const <Subject>[]).where((s) => s.key == _selection.subjectKey).firstOrNull;
        if (subject == null) return const SizedBox.shrink();

        return FutureBuilder<List<PaperEntry>>(
          future: widget.repository.getPapers(
            categoryId: _selection.category!.id,
            examTypeId: examType.id,
            subjectId: subject.id,
            system: _selection.system,
            track: _selection.track,
          ),
          builder: (context, papersSnapshot) {
            final loading = papersSnapshot.connectionState == ConnectionState.waiting;
            final papers = papersSnapshot.data ?? const <PaperEntry>[];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.space2),
                  _backHeader(subject.title,
                      subtitle: '${examType.name}${_selection.track != null ? ' · ${_selection.track}' : ''} · ${subject.code}'),
                  const SizedBox(height: AppSpacing.space4),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (papers.isEmpty)
                    _noPapersYet(l10n, subject)
                  else
                    for (final paper in papers) ...[
                      InkWell(
                        onTap: () => widget.onOpenPaper?.call(PaperSelection(
                          category: _selection.category!,
                          system: _selection.system,
                          examType: examType,
                          track: _selection.track,
                          subject: subject,
                          entry: paper,
                        )),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                          child: Row(
                            children: [
                              IconChip(icon: subject.icon, tint: subject.tint),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${examType.name} ${paper.year}', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                    Text(paper.isPublished ? l10n.paperMarkingGuideAvailable : l10n.paperUnderReview,
                                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space3),
                    ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _noPapersYet(AppLocalizations l10n, Subject subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(LucideIcons.inbox, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(l10n.noPapersYetTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(l10n.noPapersYetBody(subject.title),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _optionRow(String title, String? subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                if (subtitle != null) Text(subtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
