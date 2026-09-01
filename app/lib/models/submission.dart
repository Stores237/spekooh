import '../widgets/spekooh_badge.dart';

class Submission {
  const Submission({
    required this.id,
    required this.title,
    required this.status,
    required this.rawStatus,
    required this.tone,
    required this.date,
    this.rejectionReason,
    this.dismissedByContributor = false,
  });

  final int id;
  final String title;
  // Human-readable, localized-ish display label (e.g. "Published") — what
  // the badge on Profile actually renders.
  final String status;
  // The real backend status key (e.g. "REJECTED") — what code checks
  // against, so display-copy changes never silently break that logic.
  final String rawStatus;
  final SpekoohBadgeTone tone;
  final String date;
  // Only ever non-null when rawStatus == 'REJECTED' — the Review Team's
  // real reason (see apps.papers.services.reject_submission). Null
  // otherwise, never fabricated.
  final String? rejectionReason;
  bool get isRejected => rawStatus == 'REJECTED';
  final bool dismissedByContributor;
}
