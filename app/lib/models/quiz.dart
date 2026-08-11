import 'package:flutter/material.dart';

class Quiz {
  const Quiz({
    this.id = 0,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.questionCount,
    required this.suggestedTime,
    required this.playedCount,
    this.questions = const [],
  });

  final int id;
  final String title;
  final String subtitle;
  final IconData icon;
  final int questionCount;
  final String suggestedTime;
  final int playedCount;
  final List<QuizQuestion> questions;
}

class QuizQuestion {
  const QuizQuestion({required this.id, required this.text, required this.choices});
  final int id;
  final String text;
  final List<String> choices;
}
