import '../../models/quiz.dart';
import '../mock/mock_quizzes.dart';

abstract class QuizzesRepository {
  Future<Quiz> getDailyChallenge();
  Future<List<Quiz>> getQuizzes();
  Future<Quiz> getQuizDetail(int quizId);
  Future<int> submitAttempt(int quizId, List<int> answers);
  Future<List<({String name, int rank, String quizzes})>> getLeaderboard();

  /// Real consecutive-day daily-challenge streak — zero for an account
  /// that's never played, not a fabricated count.
  Future<({int currentStreak, bool playedToday})> getStreak();
}

class MockQuizzesRepository implements QuizzesRepository {
  /// Both default to the shared mock constants — only tests exercising a
  /// specific quiz shape (e.g. a real questionCount: 0 "not written yet"
  /// quiz) need to override either.
  MockQuizzesRepository({Quiz? dailyChallenge, List<Quiz>? quizzes})
      : _dailyChallenge = dailyChallenge ?? mockDailyChallenge,
        _quizzes = quizzes ?? mockQuizzes;

  final Quiz _dailyChallenge;
  final List<Quiz> _quizzes;

  @override
  Future<Quiz> getDailyChallenge() => Future.value(_dailyChallenge);

  @override
  Future<({int currentStreak, bool playedToday})> getStreak() async => (currentStreak: 0, playedToday: false);

  @override
  Future<List<Quiz>> getQuizzes() => Future.value(_quizzes);

  @override
  Future<Quiz> getQuizDetail(int quizId) async {
    final all = [_dailyChallenge, ..._quizzes, mockQuizDetail];
    return all.firstWhere((q) => q.id == quizId, orElse: () => mockQuizDetail);
  }

  @override
  Future<int> submitAttempt(int quizId, List<int> answers) async {
    final quiz = await getQuizDetail(quizId);
    var score = 0;
    for (var i = 0; i < answers.length && i < quiz.questions.length; i++) {
      if (answers[i] == 1) score++; // mock has no "correct" answer key — arbitrary deterministic scoring
    }
    return score;
  }

  @override
  Future<List<({String name, int rank, String quizzes})>> getLeaderboard() =>
      Future.value(mockLeaderboard);
}
