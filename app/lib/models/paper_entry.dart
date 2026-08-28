/// A real paper submission returned by the backend — as opposed to
/// [ExamCategory]/[ExamType]/[Subject], which describe the taxonomy a paper
/// belongs to, not an actual submitted paper.
class PaperEntry {
  const PaperEntry({
    required this.id,
    required this.year,
    required this.system,
    required this.track,
    required this.status,
    required this.fileUrl,
    required this.createdAt,
    this.examBoard = '',
    this.subjectTitle,
    this.examTypeName,
    this.institution = '',
    this.discipline = '',
    this.supervisorName = '',
    this.categoryKey,
    this.requiresUnlock = false,
    this.isUnlocked = false,
    this.hasMarkingGuide = false,
    this.paperDownloadUnlocked = true,
    this.paperDownloadPriceFcfa = 0,
  });

  final int id;
  final int year;
  final String? system;
  final String track;
  final String status;
  final String? fileUrl;
  final DateTime? createdAt;

  /// Free-text exam board (e.g. "Cambridge", "GCE Board") — blank means the
  /// submitter didn't specify one. Not present on list-endpoint rows, only
  /// on a fetched detail.
  final String examBoard;

  /// Denormalized display labels the list endpoint includes directly (null
  /// for the "reports" category, which has no subject).
  final String? subjectTitle;
  final String? examTypeName;

  /// Only meaningful for the "reports" category (internship/mémoire/thèse) —
  /// blank for every other submission. supervisorName is genuinely optional.
  final String institution;
  final String discipline;
  final String supervisorName;

  /// The real backend ExamCategory.key (e.g. "reports") — lets the client
  /// tell reports apart from exam papers without name-matching exam types.
  final String? categoryKey;

  /// Server-decided: can this user see [fileUrl] at all? True only for the
  /// PhD/Master's report tiers, and only until unlocked (see
  /// apps.papers.services.user_can_view_file on the backend — the
  /// submitter and staff are always exempt).
  final bool requiresUnlock;

  /// Server-decided: has this user actually paid to unlock this paper, or
  /// is it a lower-tier report (Internship/Bachelor's/HND) that's free to
  /// download outright — independent of [requiresUnlock] (owner decision;
  /// see apps.papers.services.report_download_is_free on the backend).
  final bool isUnlocked;

  /// Whether a real PublishedGuide exists for this paper — independent of
  /// [isPublished] (an exam paper can be published for students to read
  /// well before its marking guide is ready; see
  /// PaperAccessFieldsMixin.get_has_marking_guide on the backend). Never
  /// true for a report — reports have no marking-guide concept at all.
  final bool hasMarkingGuide;

  /// Exam papers only (owner decision, 2026-08-28) — a separate, smaller
  /// purchase from [isUnlocked] above: viewing an exam paper in-app is
  /// always free, but downloading/saving it costs [paperDownloadPriceFcfa],
  /// priced by exam level (see apps.papers.services.paper_download_price_fcfa
  /// on the backend). Defaults true/0 — a report or anything not fetched
  /// through the real serializer field is never gated by this.
  final bool paperDownloadUnlocked;
  final int paperDownloadPriceFcfa;

  bool get isReport => categoryKey == 'reports';

  bool get isPublished => status == 'PUBLISHED';
}
