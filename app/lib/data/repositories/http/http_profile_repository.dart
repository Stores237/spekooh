import '../../../models/achievement.dart';
import '../../../models/spekooh_user.dart';
import '../../../models/terms_status.dart';
import '../../../models/submission.dart';
import '../../../widgets/spekooh_badge.dart';
import '../../achievement_definitions.dart';
import '../../api_client.dart';
import '../papers_repository.dart' show SubmissionFile;
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
  'REJECTED': 'Not accepted',
};

const _statusTone = {
  'PUBLISHED': SpekoohBadgeTone.green,
  'MERGED': SpekoohBadgeTone.green,
  'AWAITING_MARKING_GUIDE': SpekoohBadgeTone.amber,
  'GUIDE_SUBMITTED': SpekoohBadgeTone.amber,
  'INSTRUCTOR_REQUEST_SENT': SpekoohBadgeTone.amber,
  'INSTRUCTOR_REJECTED': SpekoohBadgeTone.dark,
  'UNASSIGNED_ADMIN_QUEUE': SpekoohBadgeTone.dark,
  'REJECTED': SpekoohBadgeTone.dark,
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
    final redeemCodes = await _client.get('/credits/redeem-codes/') as List;

    // A code's status only flips to EXPIRED when someone tries to apply it, so
    // an ACTIVE row can already be past its expiry: never show that as usable.
    final now = DateTime.now();
    final activeCode = redeemCodes.cast<Map<String, dynamic>>().firstWhere(
      (c) {
        if (c['status'] != 'ACTIVE') return false;
        final expiresAt = DateTime.tryParse(c['expires_at'] as String? ?? '');
        return expiresAt == null || expiresAt.isAfter(now);
      },
      orElse: () => const {},
    );

    final joinDate = DateTime.tryParse(me['created_at'] as String? ?? '');

    return SpekoohUser(
      name: (me['name'] as String?)?.isNotEmpty == true ? me['name'] as String : 'Guest',
      joinDate: joinDate == null ? '' : '${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}',
      submissionsCount: submissions.length,
      quizzesCount: quizStats['quizzes_played'] as int? ?? 0,
      redeemCode: activeCode['code'] as String? ?? '',
      redeemCodeExpiresAt: DateTime.tryParse(activeCode['expires_at'] as String? ?? '')?.toLocal(),
      redeemCodeSubtitle: activeCode.isEmpty
          ? ''
          : '${activeCode['value_percent']}% off your next marking guide unlock',
      trialDaysRemaining: me['trial_days_remaining'] as int? ?? 0,
      firstUnlockFreeEligible: me['first_unlock_free_eligible'] as bool? ?? false,
      isPlusSubscriber: me['is_plus_subscriber'] as bool? ?? false,
      xpBalance: me['xp_balance'] as int? ?? 0,
      hasActiveSlotBonus: me['has_active_slot_bonus'] as bool? ?? false,
      referralCode: me['referral_code'] as String? ?? '',
      avatarUrl: me['avatar_url'] as String?,
      email: me['email'] as String? ?? '',
      phoneNumber: me['phone_number'] as String? ?? '',
    );
  }

  @override
  Future<TermsStatus> getTermsStatus() async {
    final me = await _client.get('/auth/me/') as Map<String, dynamic>;
    return TermsStatus(
      needsAcceptance: me['needs_terms_acceptance'] as bool? ?? false,
      version: me['terms_version'] as String? ?? '',
    );
  }

  @override
  Future<void> acceptTerms(String version) async {
    await _client.post('/auth/terms/accept/', body: {'version': version});
  }

  @override
  Future<void> setLanguagePreference(String code) async {
    await _client.patch('/auth/me/', body: {'language_pref': code});
  }

  @override
  Future<void> updateProfile({required String name, required String email, required String phoneNumber}) async {
    await _client.patch('/auth/me/', body: {
      'name': name,
      'email': email.isEmpty ? null : email,
      'phone_number': phoneNumber.isEmpty ? null : phoneNumber,
    });
  }

  @override
  Future<String?> updateAvatar(SubmissionFile file) async {
    final response = await _client.postMultipart(
      '/auth/me/',
      method: 'PATCH',
      fileFieldName: 'avatar',
      fileBytes: file.bytes,
      fileName: file.fileName,
      mimeType: file.mimeType,
    ) as Map<String, dynamic>;
    return response['avatar_url'] as String?;
  }

  @override
  Future<List<Achievement>> getAchievements(SpekoohUser user) async {
    // Owner decision, 2026-08-28: real badges computed from [user]'s real,
    // already-fetched counts (see data/achievement_definitions.dart) —
    // still no separate backend achievements endpoint/model, same
    // "compose client-side" pattern getUser() above uses.
    return computeAchievements(user);
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
        id: row['id'] as int,
        title: subjectTitle != null ? '$subjectTitle, $examTypeName $year' : '$examTypeName $year',
        status: _statusDisplay[status] ?? status,
        rawStatus: status,
        tone: _statusTone[status] ?? SpekoohBadgeTone.neutral,
        date: date == null ? '' : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        rejectionReason: (row['rejection_reason'] as String?)?.isEmpty ?? true ? null : row['rejection_reason'] as String,
        dismissedByContributor: row['dismissed_by_contributor'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<void> dismissSubmission(int id) async {
    await _client.post('/papers/submissions/$id/dismiss/');
  }
}
