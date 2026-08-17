import '../../models/achievement.dart';
import '../../models/spekooh_user.dart';
import '../../models/submission.dart';
import '../mock/mock_achievements.dart';
import '../mock/mock_submissions.dart';
import '../mock/mock_user.dart';

abstract class ProfileRepository {
  Future<SpekoohUser> getUser();
  Future<List<Achievement>> getAchievements();
  Future<List<Submission>> getSubmissions();

  /// Persists the user's language choice on their account (User.language_pref)
  /// so it follows them to other devices — see LocaleController.syncFromAccount.
  Future<void> setLanguagePreference(String code);
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({SpekoohUser? user}) : _user = user ?? mockGuestUser;

  final SpekoohUser _user;

  @override
  Future<SpekoohUser> getUser() => Future.value(_user);

  @override
  Future<List<Achievement>> getAchievements() => Future.value(mockAchievements);

  @override
  Future<List<Submission>> getSubmissions() => Future.value(mockSubmissions);

  @override
  Future<void> setLanguagePreference(String code) async {}
}
