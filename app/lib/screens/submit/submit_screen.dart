import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/papers_repository.dart';
import '../../data/repository_locator.dart';
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
/// tabs (the elevated center nav item). The "Exam paper" flow is real: it
/// walks the real taxonomy, real-picks a file, and POSTs a real multipart
/// submission. "Academic report" has no backend support yet — the
/// PaperSubmission model has no exam-type rows or discipline/institution
/// fields for the "reports" category — so that tab shows an honest
/// not-available state instead of faking a submission.
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

  @override
  void dispose() {
    _examBoardController.dispose();
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
                        child: Text('Nothing available.', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
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
    final categories = (await widget.repository.getCategories()).where((c) => c.key != ExamCategoryKey.reports).toList();
    final picked = await _pickFromList<ExamCategory>(title: 'Education level', items: categories, label: (c) => c.title);
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
      title: 'System',
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
    final types = await widget.repository.getExamTypes(_category!.key, _system);
    final picked = await _pickFromList<ExamType>(title: 'Exam type', items: types, label: (t) => t.name);
    if (picked == null) return;
    setState(() {
      _examType = picked;
      _track = null;
      _subject = null;
    });
  }

  Future<void> _pickTrack() async {
    final picked = await _pickFromList<String>(title: 'Track', items: _examType!.tracks!, label: (t) => t);
    if (picked == null) return;
    setState(() => _track = picked);
  }

  Future<void> _pickSubject() async {
    final subjects = await widget.repository.getSubjects(_examType!.name);
    final picked = await _pickFromList<Subject>(title: 'Subject', items: subjects, label: (s) => s.title);
    if (picked == null) return;
    setState(() => _subject = picked);
  }

  Future<void> _pickYear() async {
    final now = DateTime.now();
    final years = List.generate(15, (i) => now.year - i);
    final picked = await _pickFromList<int>(title: 'Year', items: years, label: (y) => '$y');
    if (picked == null) return;
    setState(() => _year = picked);
  }

  Future<void> _pickFile() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Choose PDF or image'),
              onTap: () => Navigator.of(context).pop('file'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
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
      if (mounted) setState(() => _submitError = 'Submission failed: $e');
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
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  const IconChip(icon: Icons.check, tint: IconChipTint.green, size: 64),
                  const SizedBox(height: AppSpacing.space4),
                  Text('Contribution received', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    "We'll check it against existing papers first — if it's new, it moves to instructor review. Track it under Profile.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  SpekoohButton(onPressed: _reset, child: const Text('Submit another')),
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
              Text('Contribution', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Share a past paper or an academic report — every contribution helps another student.', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    Expanded(child: _typeTab('Exam paper', _SubmitType.paper)),
                    Expanded(child: _typeTab('Academic report', _SubmitType.report)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              if (_type == _SubmitType.report) ..._reportComingSoon() else ..._paperForm(),
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _reportComingSoon() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.hourglass_empty, size: 28, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.space2),
            Text('Not available yet', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              'Academic report submissions aren\'t wired to the backend yet — only exam papers can be submitted right now. Check back soon.',
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _paperForm() {
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
              IconChip(icon: _file == null ? Icons.camera_alt_outlined : Icons.check_circle_outline, tint: IconChipTint.amber, size: 52),
              const SizedBox(height: 8),
              Text(_file == null ? 'Take a photo or upload a PDF' : _file!.fileName,
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              Text(_file == null ? 'JPG, PNG or PDF · up to 20MB' : 'Tap to replace', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.space5),
      _fieldRow('Education level', _category?.title, _pickCategory),
      if (_category?.requiresSystem ?? false)
        _fieldRow('System', _system == null ? null : (_system == ExamSystem.francophone ? 'Francophone' : 'Anglophone'), _pickSystem),
      _fieldRow('Exam type', _examType?.name, _category == null || (_category!.requiresSystem && _system == null) ? null : _pickExamType),
      if (_examType?.requiresTrack ?? false) _fieldRow('Track', _track, _pickTrack),
      _fieldRow('Subject', _subject?.title, _examType == null || (_examType!.requiresTrack && _track == null) ? null : _pickSubject),
      _fieldRow('Year', _year?.toString(), _pickYear),
      Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
        child: TextField(
          controller: _examBoardController,
          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Exam board / school (optional)', border: InputBorder.none),
        ),
      ),
      SpekoohBanner(
        icon: const Icon(Icons.card_giftcard_outlined),
        message: 'New, verified submissions earn bonus credit — redeemable toward marking-guide unlocks.',
      ),
      if (_submitError != null) ...[
        const SizedBox(height: AppSpacing.space3),
        SpekoohBanner(tone: SpekoohBannerTone.blue, icon: const Icon(Icons.error_outline), message: _submitError!),
      ],
      const SizedBox(height: AppSpacing.space5),
      SizedBox(
        width: double.infinity,
        child: SpekoohButton(
          onPressed: _canSubmit ? _submit : null,
          child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit paper'),
        ),
      ),
    ];
  }

  Widget _fieldRow(String label, String? value, VoidCallback? onTap) {
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
                Text(value ?? (enabled ? 'Select' : '—'),
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: value == null ? AppColors.textTertiary : AppColors.textPrimary)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 14, color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.4)),
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
