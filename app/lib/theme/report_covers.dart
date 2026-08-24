/// Branded default cover art for Academic Reports (owner-supplied,
/// 2026-08-23) — shown on PaperDetailScreen in place of a generic file
/// icon, matched by exam-type name. A submitted report's actual file has
/// no cover page of its own; this gives each report type a real visual
/// identity before the user opens it.
///
/// Matches by case-insensitive substring rather than exact name, so it
/// keeps working if the exam type's subtitle or surrounding copy changes —
/// only the distinguishing keyword in the name matters.
String? reportCoverAssetFor(String examTypeName) {
  final name = examTypeName.toLowerCase();
  if (name.contains('internship')) return 'assets/report_covers/internship_report.jpg';
  if (name.contains('bachelor')) return 'assets/report_covers/bachelors_report.jpg';
  if (name.contains('hnd')) return 'assets/report_covers/hnd_report.jpg';
  if (name.contains('master')) return 'assets/report_covers/masters_thesis.jpg';
  if (name.contains('phd')) return 'assets/report_covers/phd_thesis.jpg';
  return null;
}
