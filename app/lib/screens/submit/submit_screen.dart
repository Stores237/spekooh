import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
import '../../widgets/spekooh_banner.dart';
import '../../widgets/spekooh_button.dart';

enum _SubmitType { paper, report }

/// Ported from ui_kits/spekooh-app/SubmitScreen.jsx. One of the 5 bottom
/// tabs (the elevated center nav item). Both tabs are real: "Exam paper"
/// walks the real taxonomy, real-picks a file, and POSTs a real multipart
/// submission; "Academic report" does the same against the "reports"
/// category's own ExamType rows (Internship/Mémoire/Thèse/etc.) plus the
/// institution/discipline/supervisor fields specific to that category.
class SubmitScreen extends StatefulWidget {
  SubmitScreen({super.key, PapersRepository? repository})
      : repository = repository ?? RepositoryLocator.instance.papers;

  final PapersRepository repository;

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  _SubmitType _type = _SubmitType.paper;
  bool _submitting = false;
  String? _submitError;
  PaperEntry? _submitted;

  ExamCategory? _category;
  ExamSystem? _system;
  ExamType? _examType;
  String? _track;
  Subject? _subject;
  int? _year;
  final _examBoardController = TextEditingController();
  SubmissionFile? _file;

  // Academic report tab — deliberately separate state from the exam-paper
  // fields above so switching tabs never mixes the two in-progress forms.
  ExamType? _reportType;
  int? _reportYear;
  SubmissionFile? _reportFile;
  final _institutionController = TextEditingController();
  final _disciplineController = TextEditingController();
  final _supervisorController = TextEditingController();
  bool _submittingReport = false;
  String? _reportSubmitError;

  @override
  void dispose() {
    _examBoardController.dispose();
    _institutionController.dispose();
    _disciplineController.dispose();
    _supervisorController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _category != null &&
      (!_category!.requiresSystem || _system != null) &&
      _examType != null &&
      (!_examType!.requiresTrack || _track != null) &&
      _subject != null &&
      _year != null &&
      _file != null;

  bool get _canSubmitReport =>
      !_submittingReport &&
      _reportType != null &&
      _institutionController.text.trim().isNotEmpty &&
      _disciplineController.text.trim().isNotEmpty &&
      _reportYear != null &&
      _reportFile != null;

  Future<T?> _pickFromList<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                ),
              ),
              Flexible(
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(AppLocalizations.of(context)!.nothingAvailable, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(label(items[i]), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, color: AppColors.textPrimary)),
                          onTap: () => Navigator.of(context).pop(items[i]),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final title = AppLocalizations.of(context)!.educationLevelLabel;
    final categories = (await widget.repository.getCategories()).where((c) => c.key != ExamCategoryKey.reports).toList();
    if (!mounted) return;
    final picked = await _pickFromList<ExamCategory>(title: title, items: categories, label: (c) => c.title);
    if (picked == null) return;
    setState(() {
      _category = picked;
      _system = null;
      _examType = null;
      _track = null;
      _subject = null;
    });
  }

  Future<void> _pickSystem() async {
    final picked = await _pickFromList<ExamSystem>(
      title: AppLocalizations.of(context)!.systemLabel,
      items: ExamSystem.values,
      label: (s) => s == ExamSystem.francophone ? 'Francophone' : 'Anglophone',
    );
    if (picked == null) return;
    setState(() {
      _system = picked;
      _examType = null;
      _track = null;
      _subject = null;
    });
  }

  Future<void> _pickExamType() async {
    final title = AppLocalizations.of(context)!.examTypeLabel;
    final types = await widget.repository.getExamTypes(_category!.key, _system);
    if (!mounted) return;
    final picked = await _pickFromList<ExamType>(title: title, items: types, label: (t) => t.name);
    if (picked == null) return;
    setState(() {
      _examType = picked;
      _track = null;
      _subject = null;
    });
  }

  Future<void> _pickTrack() async {
    final picked = await _pickFromList<String>(title: AppLocalizations.of(context)!.trackLabel, items: _examType!.tracks!, label: (t) => t);
    if (picked == null) return;
    setState(() => _track = picked);
  }

  Future<void> _pickSubject() async {
    final title = AppLocalizations.of(context)!.subjectLabel;
    final subjects = await widget.repository.getSubjects(_examType!.name);
    if (!mounted) return;
    final picked = await _pickFromList<Subject>(title: title, items: subjects, label: (s) => s.title);
    if (picked == null) return;
    setState(() => _subject = picked);
  }

  Future<void> _pickYear() async {
    final now = DateTime.now();
    final years = List.generate(15, (i) => now.year - i);
    final picked = await _pickFromList<int>(title: AppLocalizations.of(context)!.yearLabel, items: years, label: (y) => '$y');
    if (picked == null) return;
    setState(() => _year = picked);
  }

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.fileUp),
              title: Text(l10n.choosePdfOrImage),
              onTap: () => Navigator.of(context).pop('file'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'file') {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      final picked = result?.files.single;
      if (picked?.bytes != null) {
        setState(() => _file = SubmissionFile(bytes: picked!.bytes!, fileName: picked.name, mimeType: _mimeFor(picked.extension)));
      }
    } else if (choice == 'camera') {
      final xfile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        setState(() => _file = SubmissionFile(bytes: bytes, fileName: xfile.name, mimeType: 'image/jpeg'));
      }
    }
  }

  String? _mimeFor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }

  Future<void> _pickReportType() async {
    final title = AppLocalizations.of(context)!.reportTypeLabel;
    final types = await widget.repository.getExamTypes(ExamCategoryKey.reports, null);
    if (!mounted) return;
    final picked = await _pickFromList<ExamType>(title: title, items: types, label: (t) => t.name);
    if (picked == null) return;
    setState(() => _reportType = picked);
  }

  Future<void> _pickReportYear() async {
    final now = DateTime.now();
    final years = List.generate(15, (i) => now.year - i);
    final picked = await _pickFromList<int>(title: AppLocalizations.of(context)!.yearLabel, items: years, label: (y) => '$y');
    if (picked == null) return;
    setState(() => _reportYear = picked);
  }

  Future<void> _pickReportFile() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.fileUp),
              title: Text(l10n.choosePdfOrImage),
              onTap: () => Navigator.of(context).pop('file'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'file') {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      final picked = result?.files.single;
      if (picked?.bytes != null) {
        setState(() => _reportFile = SubmissionFile(bytes: picked!.bytes!, fileName: picked.name, mimeType: _mimeFor(picked.extension)));
      }
    } else if (choice == 'camera') {
      final xfile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        setState(() => _reportFile = SubmissionFile(bytes: bytes, fileName: xfile.name, mimeType: 'image/jpeg'));
      }
    }
  }

  Future<void> _submitReport() async {
    // Fast, local check before the network round-trip — the backend is the
    // real source of truth (PaperSubmissionCreateSerializer.validate()
    // rejects it the same way), but there's no reason to make the user wait
    // for a response we can already tell will fail.
    if (_reportFile!.bytes.length > _reportType!.maxUploadMb * 1024 * 1024) {
      setState(() => _reportSubmitError = AppLocalizations.of(context)!.fileTooLargeError(_reportType!.maxUploadMb));
      return;
    }
    setState(() {
      _submittingReport = true;
      _reportSubmitError = null;
    });
    try {
      final categories = await widget.repository.getCategories();
      final reportsCategory = categories.firstWhere((c) => c.key == ExamCategoryKey.reports);
      final entry = await widget.repository.submitPaper(
        categoryId: reportsCategory.id,
        examTypeId: _reportType!.id,
        year: _reportYear!,
        institution: _institutionController.text.trim(),
        discipline: _disciplineController.text.trim(),
        supervisorName: _supervisorController.text.trim(),
        file: _reportFile!,
      );
      if (mounted) setState(() => _submitted = entry);
    } catch (e) {
      if (mounted) setState(() => _reportSubmitError = AppLocalizations.of(context)!.submissionFailed('$e'));
    } finally {
      if (mounted) setState(() => _submittingReport = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final entry = await widget.repository.submitPaper(
        categoryId: _category!.id,
        examTypeId: _examType!.id,
        subjectId: _subject!.id,
        system: _system,
        track: _track,
        year: _year!,
        examBoard: _examBoardController.text.trim(),
        file: _file!,
      );
      if (mounted) setState(() => _submitted = entry);
    } catch (e) {
      if (mounted) setState(() => _submitError = AppLocalizations.of(context)!.submissionFailed('$e'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    setState(() {
      _submitted = null;
      _submitError = null;
      _category = null;
      _system = null;
      _examType = null;
      _track = null;
      _subject = null;
      _year = null;
      _file = null;
      _examBoardController.clear();
      _reportSubmitError = null;
      _reportType = null;
      _reportYear = null;
      _reportFile = null;
      _institutionController.clear();
      _disciplineController.clear();
      _supervisorController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_submitted != null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconChip(icon: LucideIcons.check, tint: IconChipTint.green, size: 64),
                  const SizedBox(height: AppSpacing.space4),
                  Text(l10n.contributionReceivedTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    l10n.contributionReceivedBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  SpekoohButton(onPressed: _reset, child: Text(l10n.submitAnother)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              Text(l10n.contributionTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(l10n.contributionSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    Expanded(child: _typeTab(l10n.examPaperTab, _SubmitType.paper)),
                    Expanded(child: _typeTab(l10n.academicReportTab, _SubmitType.report)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              if (_type == _SubmitType.report) ..._reportForm(l10n) else ..._paperForm(l10n),
              // BottomNav's center item pokes ~24px above the bar via
              // Transform.translate, which doesn't reserve layout space —
              // without extra clearance here the Submit button (this
              // screen's primary CTA) ends up visually covered by it.
              const SizedBox(height: AppSpacing.space9 + AppSpacing.space9),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _reportForm(AppLocalizations l10n) {
    return [
      GestureDetector(
        onTap: _pickReportFile,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.gold50,
            border: Border.all(color: AppColors.gold400, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              IconChip(icon: _reportFile == null ? LucideIcons.camera : LucideIcons.checkCircle, tint: IconChipTint.amber, size: 52),
              const SizedBox(height: 8),
              Text(_reportFile == null ? l10n.takePhotoOrUploadPdf : _reportFile!.fileName,
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              Text(
                _reportFile != null
                    ? l10n.tapToReplace
                    : _reportType != null
                        ? l10n.fileFormatsHintWithSize(_reportType!.maxUploadMb)
                        : l10n.fileFormatsHint,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.space5),
      _fieldRow(l10n, l10n.reportTypeLabel, _reportType?.name, _pickReportType),
      _textFieldRow(controller: _institutionController, label: l10n.institutionLabel),
      _textFieldRow(controller: _disciplineController, label: l10n.disciplineLabel),
      _textFieldRow(controller: _supervisorController, label: l10n.supervisorOptionalLabel),
      _fieldRow(l10n, l10n.yearLabel, _reportYear?.toString(), _pickReportYear),
      SpekoohBanner(
        icon: const Icon(LucideIcons.gift),
        message: l10n.contributionBonusBanner,
      ),
      if (_reportSubmitError != null) ...[
        const SizedBox(height: AppSpacing.space3),
        SpekoohBanner(tone: SpekoohBannerTone.blue, icon: const Icon(LucideIcons.alertCircle), message: _reportSubmitError!),
      ],
      const SizedBox(height: AppSpacing.space5),
      SizedBox(
        width: double.infinity,
        child: SpekoohButton(
          onPressed: _canSubmitReport ? _submitReport : null,
          child: _submittingReport ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.submitReportButton),
        ),
      ),
    ];
  }

  Widget _textFieldRow({required TextEditingController controller, required String label}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}), // keeps the submit button's enabled state live as required fields fill in
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }

  List<Widget> _paperForm(AppLocalizations l10n) {
    return [
      GestureDetector(
        onTap: _pickFile,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.gold50,
            border: Border.all(color: AppColors.gold400, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              IconChip(icon: _file == null ? LucideIcons.camera : LucideIcons.checkCircle, tint: IconChipTint.amber, size: 52),
              const SizedBox(height: 8),
              Text(_file == null ? l10n.takePhotoOrUploadPdf : _file!.fileName,
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              Text(_file == null ? l10n.fileFormatsHint : l10n.tapToReplace, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.space5),
      _fieldRow(l10n, l10n.educationLevelLabel, _category?.title, _pickCategory),
      if (_category?.requiresSystem ?? false)
        _fieldRow(l10n, l10n.systemLabel, _system == null ? null : (_system == ExamSystem.francophone ? 'Francophone' : 'Anglophone'), _pickSystem),
      _fieldRow(l10n, l10n.examTypeLabel, _examType?.name, _category == null || (_category!.requiresSystem && _system == null) ? null : _pickExamType),
      if (_examType?.requiresTrack ?? false) _fieldRow(l10n, l10n.trackLabel, _track, _pickTrack),
      _fieldRow(l10n, l10n.subjectLabel, _subject?.title, _examType == null || (_examType!.requiresTrack && _track == null) ? null : _pickSubject),
      _fieldRow(l10n, l10n.yearLabel, _year?.toString(), _pickYear),
      Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
        child: TextField(
          controller: _examBoardController,
          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(labelText: l10n.examBoardHint, border: InputBorder.none),
        ),
      ),
      SpekoohBanner(
        icon: const Icon(LucideIcons.gift),
        message: l10n.contributionBonusBanner,
      ),
      if (_submitError != null) ...[
        const SizedBox(height: AppSpacing.space3),
        SpekoohBanner(tone: SpekoohBannerTone.blue, icon: const Icon(LucideIcons.alertCircle), message: _submitError!),
      ],
      const SizedBox(height: AppSpacing.space5),
      SizedBox(
        width: double.infinity,
        child: SpekoohButton(
          onPressed: _canSubmit ? _submit : null,
          child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.submitPaperButton),
        ),
      ),
    ];
  }

  Widget _fieldRow(AppLocalizations l10n, String label, String? value, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
            Row(
              children: [
                Text(value ?? (enabled ? l10n.selectPlaceholder : '—'),
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: value == null ? AppColors.textTertiary : AppColors.textPrimary)),
                const SizedBox(width: 6),
                Icon(LucideIcons.chevronRight, size: 14, color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String label, _SubmitType type) {
    final active = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active ? AppShadows.card : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: plusJakartaSansFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
