import '../../models/quiz.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _mockQuestions = [
  QuizQuestion(id: 1, text: 'Which organelle is the site of aerobic respiration?', choices: ['Nucleus', 'Mitochondrion', 'Ribosome', 'Golgi apparatus']),
  QuizQuestion(id: 2, text: "Enzymes are primarily made of:", choices: ['Lipids', 'Carbohydrates', 'Proteins', 'Nucleic acids']),
];

const mockDailyChallenge = Quiz(
  id: 1,
  title: 'Group VII the Halogens Quiz',
  subtitle: 'Daily challenge',
  icon: LucideIcons.flaskConical,
  questionCount: 15,
  suggestedTime: '8 min',
  playedCount: 1308,
  questions: _mockQuestions,
);

const mockQuizzes = [
  Quiz(id: 2, title: 'Biology quiz', subtitle: '18 topics', icon: LucideIcons.leaf, questionCount: 15, suggestedTime: '8 min', playedCount: 5564, questions: _mockQuestions),
  Quiz(id: 3, title: 'Chemistry quizzes', subtitle: '22 topics', icon: LucideIcons.flaskConical, questionCount: 15, suggestedTime: '8 min', playedCount: 5564, questions: _mockQuestions),
  Quiz(id: 4, title: 'Geography quizzes', subtitle: '2 topics', icon: LucideIcons.globe, questionCount: 15, suggestedTime: '8 min', playedCount: 5564, questions: _mockQuestions),
  Quiz(id: 5, title: 'Computer science', subtitle: '1 topics', icon: LucideIcons.cpu, questionCount: 15, suggestedTime: '8 min', playedCount: 5564, questions: _mockQuestions),
];

/// Detail view shown when a quiz is opened — the source's "Enzyme Quiz 2".
const mockQuizDetail = Quiz(
  id: 6,
  title: 'Enzyme Quiz 2',
  subtitle: 'Practice questions drawn from Biology past papers, checked against the instructor-authored marking guide.',
  icon: LucideIcons.leaf,
  questionCount: 15,
  suggestedTime: '8 min',
  playedCount: 5564,
  questions: _mockQuestions,
);

const mockLeaderboard = [
  (name: 'Julliete', rank: 2, quizzes: '35 QUIZZES'),
  (name: 'Jojo B.', rank: 1, quizzes: '39 QUIZZES'),
  (name: 'Billionaire K.', rank: 3, quizzes: '14 QUIZZES'),
];
