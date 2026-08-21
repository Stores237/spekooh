import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/offline_papers_store.dart';

OfflinePapersStore _buildStore({Future<List<int>> Function(String url)? download}) {
  return OfflinePapersStore(
    fileStore: InMemoryOfflineFileStore(),
    download: download ?? (url) async => [1, 2, 3],
  );
}

void main() {
  test('a freshly-bootstrapped store with nothing saved is empty', () async {
    final store = _buildStore();
    await store.bootstrap();
    expect(store.papers, isEmpty);
    expect(store.isSaved(1), isFalse);
  });

  test('save() downloads the real file and lists it', () async {
    final store = _buildStore();
    await store.bootstrap();

    await store.save(paperId: 5, title: 'Biology O-Level', subtitle: 'GCE · 2024', fileUrl: 'https://cdn.example.com/paper5.pdf');

    expect(store.isSaved(5), isTrue);
    expect(store.papers, hasLength(1));
    expect(store.papers.first.title, 'Biology O-Level');
    expect(store.papers.first.relativeFilePath, '5.pdf');
  });

  test('save() with no fileUrl throws NoOfflineFileAvailableError and saves nothing', () async {
    final store = _buildStore();
    await store.bootstrap();

    await expectLater(
      store.save(paperId: 5, title: 'x', subtitle: 'y', fileUrl: null),
      throwsA(isA<NoOfflineFileAvailableError>()),
    );
    expect(store.papers, isEmpty);
  });

  test('a failed download leaves the store untouched', () async {
    final store = _buildStore(download: (url) async => throw Exception('network down'));
    await store.bootstrap();

    await expectLater(
      store.save(paperId: 5, title: 'x', subtitle: 'y', fileUrl: 'https://cdn.example.com/paper5.pdf'),
      throwsException,
    );
    expect(store.papers, isEmpty);
  });

  test('remove() deletes the file and the index entry', () async {
    final store = _buildStore();
    await store.bootstrap();
    await store.save(paperId: 5, title: 'x', subtitle: 'y', fileUrl: 'https://cdn.example.com/paper5.pdf');

    await store.remove(5);

    expect(store.isSaved(5), isFalse);
    expect(store.papers, isEmpty);
    expect(await store.absolutePathFor(5), isNull);
  });

  test('remove() on a paper that was never saved is a harmless no-op', () async {
    final store = _buildStore();
    await store.bootstrap();
    await store.remove(999);
    expect(store.papers, isEmpty);
  });

  test('saving the same paper twice overwrites rather than duplicating', () async {
    final store = _buildStore();
    await store.bootstrap();

    await store.save(paperId: 5, title: 'First title', subtitle: 'a', fileUrl: 'https://cdn.example.com/paper5.pdf');
    await store.save(paperId: 5, title: 'Updated title', subtitle: 'b', fileUrl: 'https://cdn.example.com/paper5.pdf');

    expect(store.papers, hasLength(1));
    expect(store.papers.first.title, 'Updated title');
  });

  test('the index survives a fresh bootstrap against the same file store — real persistence, not just in-memory state', () async {
    final fileStore = InMemoryOfflineFileStore();
    final first = OfflinePapersStore(fileStore: fileStore, download: (url) async => [9, 9, 9]);
    await first.bootstrap();
    await first.save(paperId: 5, title: 'Biology', subtitle: 'a', fileUrl: 'https://cdn.example.com/p5.pdf');

    final second = OfflinePapersStore(fileStore: fileStore, download: (url) async => [9, 9, 9]);
    await second.bootstrap();

    expect(second.isSaved(5), isTrue);
    expect(second.papers.first.title, 'Biology');
  });

  test('notifies listeners on save and remove', () async {
    final store = _buildStore();
    await store.bootstrap();
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.save(paperId: 5, title: 'x', subtitle: 'y', fileUrl: 'https://cdn.example.com/p5.pdf');
    expect(notifications, 1);

    await store.remove(5);
    expect(notifications, 2);
  });
}
