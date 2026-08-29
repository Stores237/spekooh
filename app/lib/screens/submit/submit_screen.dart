import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/auth_session.dart';
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
import 'contribution_reward_screen.dart';

enum _SubmitType { paper, report }

/// Thrown by [_SubmitScreenState._createCustomSubject] when a guest tries
/// to add a subject before typing their name above — distinct from a real
/// create failure so [_SubjectPickerSheetState._submitCustom] can show a
/// specific "enter your name first" message instead of the generic one.
class _GuestNameRequiredException implements Exception {}

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

  // Owner decision: contributing shouldn't require an account, but every
  // contributor still has to be identified by a real name — shared across
  // both tabs (not duplicated per form) since it's one person's identity,
  // not a per-submission-type detail. mintGuestAccessToken() (called from
  // _submit/_submitReport) mints a one-off guest token from it — this is
  // never a real app login: isLoggedIn/AuthSession stay untouched, so
  // every other action still requires a real account, and nothing about
  // this identity survives the app closing.
  final _contributorNameController = TextEditingController();

  bool get _isGuest => !AuthSession.instance.isLoggedIn;

  @override
  void dispose() {
    _examBoardController.dispose();
    _institutionController.dispose();
    _disciplineController.dispose();
    _supervisorController.dispose();
    _contributorNameController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      (!_isGuest || _contributorNameController.text.trim().isNotEmpty) &&
      _category != null &&
      (!_category!.requiresSystem || _system != null) &&
      _examType != null &&
      (!_examType!.requiresTrack || _track != null) &&
      _subject != null &&
      _year != null &&
      _file != null;

  bool get _canSubmitReport =>
      !_submittingReport &&
      (!_isGuest || _contributorNameController.text.trim().isNotEmpty) &&
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

  /// Runs a taxonomy fetch that backs a field-picker tap (getCategories/
  /// getExamTypes/getSubjects) and turns a network failure into a visible
  /// SnackBar instead of the tap silently doing nothing — previously any of
  /// these throwing left the field looking unresponsive with zero feedback.
  Future<T?> _guardedFetch<T>(Future<T> Function() fetch) async {
    try {
      return await fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotLoadOptionsError('$e'))));
      }
      return null;
    }
  }

  Future<void> _pickCategory() async {
    final title = AppLocalizations.of(context)!.educationLevelLabel;
    final categories = await _guardedFetch(() async => (await widget.repository.getCategories()).where((c) => c.key != ExamCategoryKey.reports).toList());
    if (categories == null || !mounted) return;
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
    final types = await _guardedFetch(() => widget.repository.getExamTypes(_category!.key, _system));
    if (types == null || !mounted) return;
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
    final examTypeName = _examType!.name;
    final subjects = await _guardedFetch(() => widget.repository.getSubjects(examTypeName));
    if (subjects == null || !mounted) return;
    final picked = await showModalBottomSheet<Subject>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SubjectPickerSheet(
        subjects: subjects,
        onCreate: (title) => _createCustomSubject(title: title, examTypeName: examTypeName),
      ),
    );
    if (picked == null) return;
    setState(() => _subject = picked);
  }

  /// Backend requires the same auth bar as submitting a paper itself (see
  /// SubjectViewSet.get_permissions on the backend) — a guest has to be
  /// minted a token first, same as [_submit]/[_submitReport] do right
  /// before the real upload. Unlike those, this can happen well before the
  /// guest has necessarily typed their name (the name field sits above the
  /// paper/report form, but nothing forces filling it in before scrolling
  /// down to Subject) — [_GuestNameRequiredException] lets the picker sheet
  /// show a specific "enter your name first" message instead of the
  /// generic create-failed one for that case.
  Future<Subject> _createCustomSubject({required String title, required String examTypeName}) async {
    String? guestToken;
    if (_isGuest) {
      final name = _contributorNameController.text.trim();
      if (name.isEmpty) throw _GuestNameRequiredException();
      guestToken = await AuthSession.instance.mintGuestAccessToken(name: name);
    }
    return widget.repository.createSubject(title: title, examTypeName: examTypeName, guestAccessToken: guestToken);
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
    final types = await _guardedFetch(() => widget.repository.getExamTypes(ExamCategoryKey.reports, null));
    if (types == null || !mounted) return;
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
      final guestToken = _isGuest
          ? await AuthSession.instance.mintGuestAccessToken(name: _contributorNameController.text.trim())
          : null;
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
        guestAccessToken: guestToken,
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
      final guestToken = _isGuest
          ? await AuthSession.instance.mintGuestAccessToken(name: _contributorNameController.text.trim())
          : null;
      final entry = await widget.repository.submitPaper(
        categoryId: _category!.id,
        examTypeId: _examType!.id,
        subjectId: _subject!.id,
        system: _system,
        track: _track,
        year: _year!,
        examBoard: _examBoardController.text.trim(),
        file: _file!,
        guestAccessToken: guestToken,
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
      return ContributionRewardScreen(onSubmitAnother: _reset);
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
              if (_isGuest) ...[
                Text(l10n.contributorNameTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(l10n.contributorNameSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.space3),
                _textFieldRow(controller: _contributorNameController, label: l10n.contributorNameLabel),
                const SizedBox(height: AppSpacing.space2),
              ],
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
                Text(value ?? (enabled ? l10n.selectPlaceholder : '-'),
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

/// Subject picker for [_SubmitScreenState._pickSubject] — a normal list plus
/// an "Add a subject" row for when the curated list is missing what the
/// contributor needs. Its own StatefulWidget (not the shared _pickFromList
/// helper) since it needs local state for the inline add-subject field.
class _SubjectPickerSheet extends StatefulWidget {
  const _SubjectPickerSheet({required this.subjects, required this.onCreate});

  final List<Subject> subjects;
  final Future<Subject> Function(String title) onCreate;

  @override
  State<_SubjectPickerSheet> createState() => _SubjectPickerSheetState();
}

class _SubjectPickerSheetState extends State<_SubjectPickerSheet> {
  bool _addingCustom = false;
  bool _creating = false;
  String? _error;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitCustom() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final subject = await widget.onCreate(title);
      if (mounted) Navigator.of(context).pop(subject);
    } on _GuestNameRequiredException {
      if (mounted) {
        setState(() {
          _creating = false;
          _error = AppLocalizations.of(context)!.contributorNameRequiredForSubjectError;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _creating = false;
          _error = AppLocalizations.of(context)!.addCustomSubjectError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.subjectLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                ),
              ),
              Flexible(
                child: widget.subjects.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(l10n.nothingAvailable, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.subjects.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(widget.subjects[i].title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, color: AppColors.textPrimary)),
                          onTap: () => Navigator.of(context).pop(widget.subjects[i]),
                        ),
                      ),
              ),
              const Divider(height: 1),
              if (!_addingCustom)
                ListTile(
                  leading: const Icon(LucideIcons.plus, size: 18, color: AppColors.gold700),
                  title: Text(l10n.addCustomSubject, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.gold700)),
                  onTap: () => setState(() => _addingCustom = true),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        enabled: !_creating,
                        decoration: InputDecoration(hintText: l10n.customSubjectHint, isDense: true, border: const OutlineInputBorder()),
                        onSubmitted: (_) => _submitCustom(),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_error!, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.red500)),
                        ),
                      const SizedBox(height: 10),
                      SpekoohButton(
                        size: SpekoohButtonSize.sm,
                        onPressed: _creating ? null : _submitCustom,
                        child: _creating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                            : Text(l10n.addCustomSubjectCta),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ),
        ),
      ),
    );
  }
}
