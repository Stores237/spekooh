/// A published marking guide's real content — the merge of the in-house
/// MCQ answer key and the instructor-authored non-MCQ guide, same shape
/// backend apps.papers.models.PublishedGuide.content documents and
/// apps.instructors.services.merge_and_publish actually produces.
class MarkingGuide {
  const MarkingGuide({required this.mcqAnswers, required this.nonMcqQuestions, required this.publishedAt});

  /// Question number -> answer (e.g. {"1": "B"}) — empty when the paper has
  /// no MCQ section, never a fabricated placeholder.
  final Map<String, String> mcqAnswers;
  final List<MarkingGuideQuestion> nonMcqQuestions;
  final DateTime publishedAt;
}

class MarkingGuideQuestion {
  const MarkingGuideQuestion({required this.questionType, required this.text, required this.answer});

  /// One of SHORT_ANSWER/CALCULATION/ESSAY — see backend
  /// apps.instructors.serializers.MarkingGuideQuestionSerializer.
  final String questionType;
  final String text;
  final String answer;
}
