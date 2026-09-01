import '../../models/achievement.dart';
import '../../models/spekooh_user.dart';
import '../../models/submission.dart';
import '../achievement_definitions.dart';
import '../mock/mock_submissions.dart';
import '../mock/mock_user.dart';
import 'papers_repository.dart' show SubmissionFile;

abstract class ProfileRepository {
  Future<SpekoohUser> getUser();

  /// [user] is the already-resolved result of [getUser] — achievements are
  /// computed from its real counts (submissionsCount, quizzesCount), not a
  /// separate backend call. See data/achievement_definitions.dart.
  Future<List<Achievement>> getAchievements(SpekoohUser user);
  Future<List<Submission>> getSubmissions();

  /// Clears a rejected submission out of the contributor's own "My
  /// submissions" list (Submission.dismissedByContributor) — only valid
  /// once a real Review Team verdict has actually been given (see
  /// apps.papers.services.reject_submission); the backend rejects this call
  /// for anything not currently REJECTED. Never deletes the underlying
  /// record, just this one contributor's "seen it" acknowledgement.
  Future<void> dismissSubmission(int id);

  /// Persists the user's language choice on their account (User.language_pref)
  /// so it follows them to other devices — see LocaleController.syncFromAccount.
  Future<void> setLanguagePreference(String code);

  /// Uploads a real photo as the account's avatar, replacing any existing
  /// one. Returns the new avatar_url so the caller can update its display
  /// immediately without a second round trip.
  Future<String?> updateAvatar(SubmissionFile file);

  /// Real "Edit profile" (owner decision, 2026-08-28, adapting a reference
  /// username/email/phone edit sheet) — PATCH /auth/me/, which already
  /// accepted these fields server-side before this existed on the client.
  /// Changing [email] resets the account's verification status and sends a
  /// fresh code (see UserSerializer.update on the backend) — an unverified
  /// email is never silently left looking verified.
  Future<void> updateProfile({required String name, required String email, required String phoneNumber});
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({SpekoohUser? user}) : _user = user ?? mockGuestUser;

  final SpekoohUser _user;
  // Own mutable copy per instance — dismissSubmission below mutates this,
  // and reusing the shared `mockSubmissions` const list directly would leak
  // state between tests/instances.
  final List<Submission> _submissions = List.of(mockSubmissions);

  @override
  Future<SpekoohUser> getUser() => Future.value(_user);

  @override
  Future<List<Achievement>> getAchievements(SpekoohUser user) => Future.value(computeAchievements(user));

  @override
  Future<List<Submission>> getSubmissions() => Future.value(List.unmodifiable(_submissions));

  @override
  Future<void> dismissSubmission(int id) async {
    final index = _submissions.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final s = _submissions[index];
    _submissions[index] = Submission(
      id: s.id,
      title: s.title,
      status: s.status,
      rawStatus: s.rawStatus,
      tone: s.tone,
      date: s.date,
      rejectionReason: s.rejectionReason,
      dismissedByContributor: true,
    );
  }

  @override
  Future<void> setLanguagePreference(String code) async {}

  @override
  Future<String?> updateAvatar(SubmissionFile file) => Future.value(null);

  @override
  Future<void> updateProfile({required String name, required String email, required String phoneNumber}) async {}
}
