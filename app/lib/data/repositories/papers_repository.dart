import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/exam_taxonomy.dart';
import '../../models/paper_entry.dart';
import '../../models/subject.dart';
import '../../widgets/icon_chip.dart';
import '../mock/mock_taxonomy.dart';

/// A file picked on-device, ready to upload — kept decoupled from any
/// specific file-picker package so the repository interface doesn't leak
/// a third-party type.
class SubmissionFile {
  const SubmissionFile({required this.bytes, required this.fileName, this.mimeType});
  final List<int> bytes;
  final String fileName;
  final String? mimeType;
}

abstract class PapersRepository {
  Future<List<ExamCategory>> getCategories();

  /// Also how "Academic report" types are fetched — [ExamCategoryKey.reports]
  /// is a real category with real ExamType rows now (Internship/Mémoire/
  /// Thèse/etc.), not a separate concept.
  Future<List<ExamType>> getExamTypes(ExamCategoryKey category, ExamSystem? system);
  Future<List<Subject>> getSubjects(String examTypeName);

  /// Lets a contributor add a subject the curated list is missing.
  /// [examTypeName] (not a raw language code) so the EN/FR heuristic stays
  /// centralized in one place, same as [getSubjects]. The backend
  /// get-or-creates by a slugified key, so retyping an existing subject
  /// (any casing) just returns that one instead of duplicating it.
  ///
  /// The backend requires the same auth bar as submitting a paper itself
  /// (a real account or a minted guest one) — [guestAccessToken] is that
  /// guest token for a caller who isn't logged in, same idea as
  /// [submitPaper]'s param of the same name. Null for a logged-in caller.
  Future<Subject> createSubject({required String title, required String examTypeName, String? guestAccessToken});

  /// Real submitted papers for a resolved subject — not the taxonomy, the
  /// actual [PaperEntry] rows. Empty means genuinely no papers yet.
  Future<List<PaperEntry>> getPapers({
    required int categoryId,
    required int examTypeId,
    int? subjectId,
    ExamSystem? system,
    String? track,
  });

  Future<PaperEntry> submitPaper({
    required int categoryId,
    required int examTypeId,
    int? subjectId,
    ExamSystem? system,
    String? track,
    required int year,
    String examBoard,
    // Only meaningful for the "reports" category — see PaperEntry.
    String institution = '',
    String discipline = '',
    String supervisorName = '',
    required SubmissionFile file,
    // Set only when the caller isn't logged in — see
    // AuthSession.mintGuestAccessToken. Authorizes this one request without
    // this being (or becoming) a real app login.
    String? guestAccessToken,
  });

  /// Fetches the full record for one paper (adds file_url/exam_board, not
  /// present on the lightweight rows [getPapers] returns).
  Future<PaperEntry> getPaperDetail(int paperId);

  /// The most recently published paper across all subjects — real content
  /// for Home's "featured paper" card. Null means genuinely nothing has
  /// been published yet, not a fabricated placeholder.
  Future<PaperEntry?> getLatestPublished();

  /// Registers a real paper view against the 3-free-views/day paywall.
  /// Throws [PaywallException] once the daily limit (and any ad-earned
  /// bonus view) is exhausted.
  Future<void> recordView(int paperId);

  /// Records a completed rewarded-ad watch, granting one bonus view that
  /// the next [recordView] call will consume instead of throwing
  /// [PaywallException]. Called once [RewardedAdController.showAd] confirms
  /// the reward was actually earned — never on an ad the user skipped.
  /// Not tied to a specific paper: the backend consumes it against
  /// whichever view is blocked next, so no paperId is passed.
  Future<void> recordAdWatch();

  /// Unlocks a marking guide for real money (via the backend's
  /// MockPaymentProvider). Returns the amount actually charged (after any
  /// redeem code discount).
  Future<int> unlockPaper(int paperId, {String? redeemCode});

  /// Exam papers only — a separate, smaller purchase from [unlockPaper]
  /// above: unlocks downloading/saving the paper's actual scanned file
  /// (viewing in-app is always free). Returns the amount actually charged,
  /// priced by exam level (see PaperEntry.paperDownloadPriceFcfa).
  Future<int> unlockPaperDownload(int paperId);

  /// Flags a paper for Review Team attention (spec §3.2). [reason] must be
  /// one of [paperFlagReasonKeys]. Throws [AlreadyReportedException] if
  /// this user already reported this paper — one flag per user per paper.
  Future<void> reportPaper(int paperId, {required String reason, String details});

  /// AI-generated summary of a paper's own extracted text (apps.ai on the
  /// backend — Gemini, cron-generated, cached per paper). Never throws:
  /// AI_ENABLED being off, the paper not being visible/viewable to this
  /// caller (a paywalled report — same gate as [PaperEntry.requiresUnlock],
  /// so callers should just not call this at all when that's true rather
  /// than rely on this returning null for it), and any genuine network
  /// failure all collapse to null. This is a nice-to-have enhancement, not
  /// core enough to justify an error state on the paper detail screen.
  Future<PaperSummaryResult?> getPaperSummary(int paperId);

  /// Sends the student's own running conversation about this paper to the
  /// real-time chatbot (Lane B — apps.ai.views.PaperChatView, Groq) and
  /// returns the assistant's reply. [messages] is the full conversation so
  /// far, oldest first, ending on the student's newest message — nothing
  /// is persisted server-side, so the caller owns keeping this list.
  ///
  /// Requires a real (non-guest) login — throws normally (a 401/403
  /// [ApiException]) otherwise, same as any other authenticated-only
  /// action in this app; callers should check
  /// [AuthSession.isLoggedIn]/prompt a real login before calling this at
  /// all rather than relying on that. Throws [ChatQuotaExceededException]
  /// once today's free quota is used — see [ChatReply.quotaRemaining] to
  /// show a running count before then.
  Future<ChatReply> sendChatMessage(int paperId, List<ChatMessage> messages);
}

class ChatMessage {
  const ChatMessage({required this.role, required this.content});
  final String role; // 'user' | 'assistant' — mirrors apps.ai.services.validate_chat_messages
  final String content;
}

class ChatReply {
  const ChatReply({required this.content, this.quotaRemaining});
  final String content;

  /// Free messages left today, or null for a Subscription-active (Kawlo
  /// Plus) user, who has no cap to count down (see PaperChatView).
  final int? quotaRemaining;
}

/// Carries no message — the UI supplies its own upgrade-prompt copy at the
/// catch site (see ChatScreen), same reasoning as PaywallException.
class ChatQuotaExceededException implements Exception {
  const ChatQuotaExceededException();
}

/// Mirrors apps.ai.models.ArtifactStatus — [ready] is the only one with a
/// non-empty [PaperSummaryResult.body].
enum PaperSummaryStatus { pending, running, ready, failed }

class PaperSummaryResult {
  const PaperSummaryResult({required this.status, this.body});
  final PaperSummaryStatus status;
  final String? body;
}

/// Carries no message — there's exactly one reason this fires (the daily
/// free-view limit), so the UI supplies the localized text at the catch
/// site rather than this data layer baking in fixed English.
class PaywallException implements Exception {
  const PaywallException();
}

/// Carries no message — see PaywallException.
class AlreadyReportedException implements Exception {
  const AlreadyReportedException();
}

/// Mirrors apps.papers.models.PaperFlagReason on the backend — sent to the
/// API as-is. Display labels are a UI/l10n concern (see paper_detail_screen's
/// reasonLabels), not this data layer's, so only the ordered keys live here.
const paperFlagReasonKeys = <String>[
  'WRONG_ANSWERS',
  'POOR_QUALITY',
  'WRONG_SUBJECT',
  'DUPLICATE',
  'COPYRIGHT',
  'OTHER',
];

class MockPapersRepository implements PapersRepository {
  /// [seedPublished] lets widget tests exercise the "tap a real paper"
  /// flow without a backend — real usage always starts empty, an honest
  /// "no papers yet" state until something is actually submitted+published.
  MockPapersRepository({List<PaperEntry> seedPublished = const []}) : _submitted = List.of(seedPublished);

  final List<PaperEntry> _submitted;
  int _nextId = 9000;
  final Set<int> _reportedPaperIds = {};

  @override
  Future<List<ExamCategory>> getCategories() => Future.value(MockTaxonomy.categories);

  @override
  Future<List<ExamType>> getExamTypes(ExamCategoryKey category, ExamSystem? system) =>
      Future.value(MockTaxonomy.examTypesFor(category, system));

  @override
  Future<List<Subject>> getSubjects(String examTypeName) =>
      Future.value(MockTaxonomy.subjectsForExamType(examTypeName));

  @override
  Future<Subject> createSubject({required String title, required String examTypeName, String? guestAccessToken}) =>
      Future.value(Subject(key: title.trim().toLowerCase(), title: title.trim(), tint: IconChipTint.blue, icon: LucideIcons.circle, code: ''));

  @override
  Future<List<PaperEntry>> getPapers({
    required int categoryId,
    required int examTypeId,
    int? subjectId,
    ExamSystem? system,
    String? track,
  }) async {
    return _submitted.where((p) => p.status == 'PUBLISHED').toList();
  }

  @override
  Future<PaperEntry> submitPaper({
    required int categoryId,
    required int examTypeId,
    int? subjectId,
    ExamSystem? system,
    String? track,
    required int year,
    String examBoard = '',
    String institution = '',
    String discipline = '',
    String supervisorName = '',
    required SubmissionFile file,
    String? guestAccessToken,
  }) async {
    final entry = PaperEntry(
      id: _nextId++,
      year: year,
      system: system?.name,
      track: track ?? '',
      status: 'PENDING_REVIEW',
      fileUrl: null,
      createdAt: DateTime.now(),
      institution: institution,
      discipline: discipline,
      supervisorName: supervisorName,
    );
    _submitted.add(entry);
    return entry;
  }

  @override
  Future<PaperEntry> getPaperDetail(int paperId) async =>
      _submitted.firstWhere((p) => p.id == paperId, orElse: () => _submitted.first);

  @override
  Future<PaperEntry?> getLatestPublished() async {
    final published = _submitted.where((p) => p.status == 'PUBLISHED').toList();
    return published.isEmpty ? null : published.first;
  }

  @override
  Future<void> recordView(int paperId) async {}

  @override
  Future<void> recordAdWatch() async {}

  @override
  Future<int> unlockPaper(int paperId, {String? redeemCode}) async => 500;

  @override
  Future<int> unlockPaperDownload(int paperId) async => 75;

  @override
  Future<void> reportPaper(int paperId, {required String reason, String details = ''}) async {
    if (!_reportedPaperIds.add(paperId)) {
      throw const AlreadyReportedException();
    }
  }

  /// Null by default — real usage starts with nothing generated yet. Set
  /// [mockSummary] in a test to exercise the generating/ready states.
  PaperSummaryResult? mockSummary;

  @override
  Future<PaperSummaryResult?> getPaperSummary(int paperId) async => mockSummary;

  /// A canned reply by default. Set [mockChatError] to make the next call
  /// throw instead (e.g. `const ChatQuotaExceededException()`).
  ChatReply mockChatReply = const ChatReply(content: 'This is a mock reply.', quotaRemaining: 14);
  Object? mockChatError;
  final List<List<ChatMessage>> chatCalls = [];

  @override
  Future<ChatReply> sendChatMessage(int paperId, List<ChatMessage> messages) async {
    chatCalls.add(messages);
    final error = mockChatError;
    if (error != null) throw error;
    return mockChatReply;
  }
}
