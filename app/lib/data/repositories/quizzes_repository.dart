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
  @override
  Future<Quiz> getDailyChallenge() => Future.value(mockDailyChallenge);

  @override
  Future<({int currentStreak, bool playedToday})> getStreak() async => (currentStreak: 0, playedToday: false);

  @override
  Future<List<Quiz>> getQuizzes() => Future.value(mockQuizzes);

  @override
  Future<Quiz> getQuizDetail(int quizId) async {
    final all = [mockDailyChallenge, ...mockQuizzes, mockQuizDetail];
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
