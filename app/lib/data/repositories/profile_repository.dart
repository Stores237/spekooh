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

  @override
  Future<SpekoohUser> getUser() => Future.value(_user);

  @override
  Future<List<Achievement>> getAchievements(SpekoohUser user) => Future.value(computeAchievements(user));

  @override
  Future<List<Submission>> getSubmissions() => Future.value(mockSubmissions);

  @override
  Future<void> setLanguagePreference(String code) async {}

  @override
  Future<String?> updateAvatar(SubmissionFile file) => Future.value(null);

  @override
  Future<void> updateProfile({required String name, required String email, required String phoneNumber}) async {}
}
