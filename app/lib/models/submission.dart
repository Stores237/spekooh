import '../widgets/spekooh_badge.dart';

class Submission {
  const Submission({
    required this.title,
    required this.status,
    required this.tone,
    required this.date,
  });

  final String title;
  final String status;
  final SpekoohBadgeTone tone;
  final String date;
}
