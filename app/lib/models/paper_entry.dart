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

  bool get isPublished => status == 'PUBLISHED';
}
