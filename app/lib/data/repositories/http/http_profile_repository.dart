import '../../../models/achievement.dart';
import '../../../models/spekooh_user.dart';
import '../../../models/submission.dart';
import '../../../widgets/spekooh_badge.dart';
import '../../api_client.dart';
import '../profile_repository.dart';

const _statusDisplay = {
  'PENDING_REVIEW': 'Pending review',
  'INSTRUCTOR_REQUEST_SENT': 'Routing to instructor',
  'INSTRUCTOR_ACCEPTED': 'Instructor assigned',
  'INSTRUCTOR_REJECTED': 'Needs re-routing',
  'AWAITING_MARKING_GUIDE': 'Marking guide in progress',
  'GUIDE_SUBMITTED': 'Under review',
  'MERGED': 'Merging',
  'PUBLISHED': 'Published',
  'UNASSIGNED_ADMIN_QUEUE': 'Needs admin review',
};

const _statusTone = {
  'PUBLISHED': SpekoohBadgeTone.green,
  'MERGED': SpekoohBadgeTone.green,
  'AWAITING_MARKING_GUIDE': SpekoohBadgeTone.amber,
  'GUIDE_SUBMITTED': SpekoohBadgeTone.amber,
  'INSTRUCTOR_REQUEST_SENT': SpekoohBadgeTone.amber,
  'INSTRUCTOR_REJECTED': SpekoohBadgeTone.dark,
  'UNASSIGNED_ADMIN_QUEUE': SpekoohBadgeTone.dark,
};

/// Composes the profile summary client-side from several already-existing,
/// already-tested endpoints rather than adding a new cross-app aggregation
/// endpoint server-side (which would invert the accounts<-papers/credits
/// dependency direction the backend was built with).
class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._client);
  final ApiClient _client;

  @override
  Future<SpekoohUser> getUser() async {
    final me = await _client.get('/auth/me/') as Map<String, dynamic>;
    final userId = me['id'] as String;

    final submissions = await _client.get('/papers/submissions/', query: {'submitted_by': userId}) as List;
    final quizStats = await _client.get('/quizzes/my_stats/') as Map<String, dynamic>;
    final ledger = await _client.get('/credits/ledger/') as List;
    final redeemCodes = await _client.get('/credits/redeem-codes/') as List;

    final creditBalance = ledger.fold<int>(0, (sum, entry) => sum + (entry['amount'] as int));
    final activeCode = redeemCodes.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['status'] == 'ACTIVE',
          orElse: () => const {},
        );

    final joinDate = DateTime.tryParse(me['created_at'] as String? ?? '');

    return SpekoohUser(
      name: (me['name'] as String?)?.isNotEmpty == true ? me['name'] as String : 'Guest',
      joinDate: joinDate == null ? '' : '${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}',
      submissionsCount: submissions.length,
      quizzesCount: quizStats['quizzes_played'] as int? ?? 0,
      creditBalance: creditBalance,
      redeemCode: activeCode['code'] as String? ?? '',
      redeemCodeSubtitle: activeCode.isEmpty
          ? ''
          : '${activeCode['value_percent']}% off your next marking guide unlock',
      trialDaysRemaining: me['trial_days_remaining'] as int? ?? 0,
      firstUnlockFreeEligible: me['first_unlock_free_eligible'] as bool? ?? false,
    );
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    // No backend concept for achievements/gamification — not in the confirmed
    // spec (see the backend-wiring plan's "explicitly out of scope"). Empty
    // rather than mock data, since mock content would misrepresent a real
    // logged-in user's progress.
    return const [];
  }

  @override
  Future<List<Submission>> getSubmissions() async {
    final me = await _client.get('/auth/me/') as Map<String, dynamic>;
    final rows = await _client.get('/papers/submissions/', query: {'submitted_by': me['id'] as String}) as List;
    return rows.map((row) {
      final status = row['status'] as String;
      final subjectTitle = row['subject_title'] as String?;
      final examTypeName = row['exam_type_name'] as String;
      final year = row['year'] as int;
      final date = DateTime.tryParse(row['created_at'] as String? ?? '');
      return Submission(
        title: subjectTitle != null ? '$subjectTitle — $examTypeName $year' : '$examTypeName $year',
        status: _statusDisplay[status] ?? status,
        tone: _statusTone[status] ?? SpekoohBadgeTone.neutral,
        date: date == null ? '' : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
    }).toList();
  }
}
