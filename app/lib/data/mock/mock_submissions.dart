import '../../models/submission.dart';
import '../../widgets/spekooh_badge.dart';

const mockSubmissions = [
  Submission(
    title: 'Physics, GCE A Level 2025',
    status: 'Live',
    tone: SpekoohBadgeTone.green,
    date: 'Published · earned 150 credits',
  ),
  Submission(
    title: 'Further Maths, GCE A Level 2024',
    status: 'Approved',
    tone: SpekoohBadgeTone.blue,
    date: 'Marking guide in progress',
  ),
  Submission(
    title: 'Biology, GCE O Level 2025',
    status: 'Under review',
    tone: SpekoohBadgeTone.amber,
    date: 'Checking for duplicates',
  ),
  Submission(
    title: 'History, Baccalauréat 2023',
    status: 'Received',
    tone: SpekoohBadgeTone.neutral,
    date: 'Just submitted',
  ),
];
