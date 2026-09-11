import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_guides_store.dart';
import 'package:spekooh/models/marking_guide.dart';

final _guide = MarkingGuide(
  mcqAnswers: const {'1': 'B', '2': 'A'},
  nonMcqQuestions: const [
    MarkingGuideQuestion(questionType: 'SHORT_ANSWER', text: 'Name the site of aerobic respiration.', answer: 'The mitochondrion.'),
  ],
  publishedAt: DateTime(2026, 9, 1),
);

OfflineGuidesStore _buildStore() => OfflineGuidesStore(fileStore: InMemoryOfflineFileStore());

void main() {
  test('a freshly-bootstrapped store with nothing saved is empty', () async {
    final store = _buildStore();
    await store.bootstrap();
    expect(store.guides, isEmpty);
    expect(store.isSaved(1), isFalse);
  });

  test('save() lists the guide with its real content', () async {
    final store = _buildStore();
    await store.bootstrap();

    await store.save(paperId: 5, title: 'Biology O-Level', guide: _guide);

    expect(store.isSaved(5), isTrue);
    expect(store.guides, hasLength(1));
    expect(store.guides.first.title, 'Biology O-Level');
    expect(store.guides.first.mcqAnswers, {'1': 'B', '2': 'A'});
    expect(store.guides.first.nonMcqQuestions.single.answer, 'The mitochondrion.');
  });

  test('remove() deletes the index entry', () async {
    final store = _buildStore();
    await store.bootstrap();
    await store.save(paperId: 5, title: 'x', guide: _guide);

    await store.remove(5);

    expect(store.isSaved(5), isFalse);
    expect(store.guides, isEmpty);
  });

  test('remove() on a guide that was never saved is a harmless no-op', () async {
    final store = _buildStore();
    await store.bootstrap();
    await store.remove(999);
    expect(store.guides, isEmpty);
  });

  test('saving the same guide twice overwrites rather than duplicating', () async {
    final store = _buildStore();
    await store.bootstrap();

    await store.save(paperId: 5, title: 'First title', guide: _guide);
    await store.save(paperId: 5, title: 'Updated title', guide: _guide);

    expect(store.guides, hasLength(1));
    expect(store.guides.first.title, 'Updated title');
  });

  test('the index survives a fresh bootstrap against the same file store — real persistence, not just in-memory state', () async {
    final fileStore = InMemoryOfflineFileStore();
    final first = OfflineGuidesStore(fileStore: fileStore);
    await first.bootstrap();
    await first.save(paperId: 5, title: 'Biology', guide: _guide);

    final second = OfflineGuidesStore(fileStore: fileStore);
    await second.bootstrap();

    expect(second.isSaved(5), isTrue);
    expect(second.guides.first.title, 'Biology');
  });

  test('notifies listeners on save and remove', () async {
    final store = _buildStore();
    await store.bootstrap();
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.save(paperId: 5, title: 'x', guide: _guide);
    expect(notifications, 1);

    await store.remove(5);
    expect(notifications, 2);
  });
}
