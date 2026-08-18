import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/quiz.dart';
import '../../api_client.dart';
import '../quizzes_repository.dart';

class HttpQuizzesRepository implements QuizzesRepository {
  HttpQuizzesRepository(this._client);
  final ApiClient _client;

  Quiz _fromJson(Map<String, dynamic> row) {
    final questionsJson = row['questions'] as List?;
    return Quiz(
      id: row['id'] as int,
      title: row['title'] as String,
      subtitle: row['subtitle'] as String? ?? '',
      // The backend quiz model carries no icon (cosmetic-only) — fixed placeholder.
      icon: LucideIcons.zap,
      questionCount: row['question_count'] as int? ?? 0,
      suggestedTime: '${((row['suggested_time_seconds'] as int? ?? 0) / 60).round()} min',
      playedCount: row['played_count'] as int? ?? 0,
      questions: questionsJson == null
          ? const []
          : questionsJson
              .map((q) => QuizQuestion(
                    id: q['id'] as int,
                    text: q['text'] as String,
                    choices: (q['choices'] as List).map((c) => c as String).toList(),
                  ))
              .toList(),
    );
  }

  @override
  Future<Quiz> getDailyChallenge() async {
    final row = await _client.get('/quizzes/daily_challenge/');
    return _fromJson(row as Map<String, dynamic>);
  }

  @override
  Future<List<Quiz>> getQuizzes() async {
    final rows = await _client.get('/quizzes/') as List;
    return rows.map((row) => _fromJson(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<Quiz> getQuizDetail(int quizId) async {
    final row = await _client.get('/quizzes/$quizId/');
    return _fromJson(row as Map<String, dynamic>);
  }

  @override
  Future<int> submitAttempt(int quizId, List<int> answers) async {
    final row = await _client.post('/quizzes/$quizId/submit/', body: {'answers': answers});
    return row['score'] as int;
  }

  @override
  Future<List<({String name, int rank, String quizzes})>> getLeaderboard() async {
    final rows = await _client.get('/quizzes/leaderboard/') as List;
    return rows.map((row) {
      return (
        name: row['name'] as String,
        rank: row['rank'] as int,
        quizzes: '${row['quizzes_played']} QUIZZES',
      );
    }).toList();
  }

  @override
  Future<({int currentStreak, bool playedToday})> getStreak() async {
    final row = await _client.get('/quizzes/streak/') as Map<String, dynamic>;
    return (currentStreak: row['current_streak'] as int, playedToday: row['played_today'] as bool);
  }
}
