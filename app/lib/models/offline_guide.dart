import 'marking_guide.dart';

/// A marking guide's content saved to on-device storage for offline
/// reading — unlike [OfflinePaper], there's no separate binary file to
/// store: the guide's own real content (already just JSON on the backend,
/// see PublishedGuide.content) is small enough to keep directly in
/// [OfflineGuidesStore]'s index, one entry per saved guide.
class OfflineGuide {
  const OfflineGuide({
    required this.paperId,
    required this.title,
    required this.mcqAnswers,
    required this.nonMcqQuestions,
    required this.publishedAt,
    required this.savedAt,
  });

  final int paperId;
  final String title;
  final Map<String, String> mcqAnswers;
  final List<MarkingGuideQuestion> nonMcqQuestions;
  final DateTime publishedAt;
  final DateTime savedAt;

  MarkingGuide toMarkingGuide() => MarkingGuide(mcqAnswers: mcqAnswers, nonMcqQuestions: nonMcqQuestions, publishedAt: publishedAt);

  Map<String, dynamic> toJson() => {
        'paperId': paperId,
        'title': title,
        'mcqAnswers': mcqAnswers,
        'nonMcqQuestions': nonMcqQuestions
            .map((q) => {'questionType': q.questionType, 'text': q.text, 'answer': q.answer})
            .toList(),
        'publishedAt': publishedAt.toIso8601String(),
        'savedAt': savedAt.toIso8601String(),
      };

  factory OfflineGuide.fromJson(Map<String, dynamic> json) => OfflineGuide(
        paperId: json['paperId'] as int,
        title: json['title'] as String,
        mcqAnswers: (json['mcqAnswers'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String)),
        nonMcqQuestions: (json['nonMcqQuestions'] as List)
            .map((q) => MarkingGuideQuestion(
                  questionType: q['questionType'] as String,
                  text: q['text'] as String,
                  answer: q['answer'] as String,
                ))
            .toList(),
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}
