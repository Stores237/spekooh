import '../../models/submission.dart';
import '../../widgets/spekooh_badge.dart';

const mockSubmissions = [
  Submission(
    id: 1,
    title: 'Physics, GCE A Level 2025',
    status: 'Live',
    rawStatus: 'PUBLISHED',
    tone: SpekoohBadgeTone.green,
    date: 'Published · earned 150 credits',
  ),
  Submission(
    id: 2,
    title: 'Further Maths, GCE A Level 2024',
    status: 'Approved',
    rawStatus: 'GUIDE_SUBMITTED',
    tone: SpekoohBadgeTone.blue,
    date: 'Marking guide in progress',
  ),
  Submission(
    id: 3,
    title: 'Biology, GCE O Level 2025',
    status: 'Under review',
    rawStatus: 'PENDING_REVIEW',
    tone: SpekoohBadgeTone.amber,
    date: 'Checking for duplicates',
  ),
  Submission(
    id: 4,
    title: 'History, Baccalauréat 2023',
    status: 'Received',
    rawStatus: 'PENDING_REVIEW',
    tone: SpekoohBadgeTone.neutral,
    date: 'Just submitted',
  ),
];
