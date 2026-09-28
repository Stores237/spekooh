// The Spekooh Assistant's saved chats: on this phone only, per account, and
// never allowed to get in the way of chatting.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/assistant_history_store.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/repositories/assistant_repository.dart';
import 'package:spekooh/models/assistant_session.dart';

AssistantSession _session(String id, {DateTime? updatedAt, int messages = 2, String title = 'Physics help'}) => AssistantSession(
      id: id,
      title: title,
      createdAt: DateTime(2026, 9, 28, 8),
      updatedAt: updatedAt ?? DateTime(2026, 9, 28, 9),
      messages: [
        for (var i = 0; i < messages; i++) ChatMessage(role: i.isEven ? 'user' : 'assistant', content: 'message $i'),
      ],
    );

class _BrokenStorage implements OfflineFileStore {
  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) async => throw Exception('disk full');
  @override
  Future<List<int>?> readBytes(String relativePath) async => throw Exception('unreadable');
  @override
  Future<void> delete(String relativePath) async => throw Exception('unavailable');
  @override
  Future<String> absolutePathFor(String relativePath) async => '';
}

void main() {
  late InMemoryOfflineFileStore files;
  String? userId;
  late AssistantHistoryStore store;

  setUp(() {
    files = InMemoryOfflineFileStore();
    userId = 'user-a';
    store = AssistantHistoryStore(fileStore: files, currentUserId: () => userId);
  });

  test('starts empty', () async {
    expect(await store.list(), isEmpty);
  });

  test('saved chats come back newest first, with their messages intact', () async {
    await store.save(_session('old', updatedAt: DateTime(2026, 9, 1)));
    await store.save(_session('new', updatedAt: DateTime(2026, 9, 20), title: 'Newest'));

    final chats = await store.list();

    expect(chats.map((s) => s.id).toList(), ['new', 'old']);
    expect(chats.first.title, 'Newest');
    expect(chats.first.messages.map((m) => m.content).toList(), ['message 0', 'message 1']);
    expect(chats.first.messages.first.role, 'user');
  });

  test('saving the same chat again replaces it instead of adding a second one', () async {
    await store.save(_session('a', messages: 2));
    await store.save(_session('a', messages: 4, updatedAt: DateTime(2026, 9, 29)));

    final chats = await store.list();

    expect(chats, hasLength(1));
    expect(chats.single.messages, hasLength(4));
  });

  test('only the most recent chats are kept once there are too many', () async {
    final small = AssistantHistoryStore(fileStore: files, currentUserId: () => userId, maxSessions: 3);
    for (var day = 1; day <= 5; day++) {
      await small.save(_session('chat-$day', updatedAt: DateTime(2026, 9, day)));
    }

    expect((await small.list()).map((s) => s.id).toList(), ['chat-5', 'chat-4', 'chat-3']);
  });

  test('a very long chat keeps only its most recent messages', () async {
    final small = AssistantHistoryStore(fileStore: files, currentUserId: () => userId, maxMessagesPerSession: 4);

    await small.save(_session('long', messages: 10));

    final kept = (await small.list()).single.messages;
    expect(kept.map((m) => m.content).toList(), ['message 6', 'message 7', 'message 8', 'message 9']);
  });

  test('deleting removes just that chat', () async {
    await store.save(_session('a'));
    await store.save(_session('b', updatedAt: DateTime(2026, 9, 29)));

    await store.delete('a');

    expect((await store.list()).map((s) => s.id).toList(), ['b']);
  });

  test('clearing removes every chat', () async {
    await store.save(_session('a'));
    await store.save(_session('b'));

    await store.clear();

    expect(await store.list(), isEmpty);
  });

  test('another account on the same phone never sees these chats', () async {
    await store.save(_session('mine'));

    userId = 'user-b';

    expect(await store.list(), isEmpty);
    await store.save(_session('theirs'));
    expect((await store.list()).map((s) => s.id).toList(), ['theirs']);

    userId = 'user-a';
    expect((await store.list()).map((s) => s.id).toList(), ['mine']);
  });

  test('an account id with unusual characters cannot escape its own file', () async {
    userId = '../../etc/passwd';

    await store.save(_session('x'));

    expect(await store.list(), hasLength(1));
  });

  test('a damaged file looks like an empty history instead of an error', () async {
    await files.writeBytes('sessions_user-a.json', utf8.encode('{ this is not json'));

    expect(await store.list(), isEmpty);
    await store.save(_session('recovers')); // and saving works again afterwards
    expect((await store.list()).map((s) => s.id).toList(), ['recovers']);
  });

  test('one unreadable entry does not cost the student every other chat', () async {
    await store.save(_session('good'));
    final raw = jsonDecode(utf8.decode((await files.readBytes('sessions_user-a.json'))!)) as List;
    raw.add({'id': 'broken'}); // missing everything else
    await files.writeBytes('sessions_user-a.json', utf8.encode(jsonEncode(raw)));

    expect((await store.list()).map((s) => s.id).toList(), ['good']);
  });

  test('a storage failure never throws: history is best effort', () async {
    final broken = AssistantHistoryStore(fileStore: _BrokenStorage(), currentUserId: () => userId);

    expect(await broken.list(), isEmpty);
    await broken.save(_session('a'));
    await broken.delete('a');
    await broken.clear();
  });

  group('titles', () {
    ChatMessage user(String text) => ChatMessage(role: 'user', content: text);

    test('is the first thing the student asked', () {
      expect(AssistantSession.titleFor([user('Explain Newton\'s laws'), const ChatMessage(role: 'assistant', content: 'Sure')]), "Explain Newton's laws");
    });

    test('is one tidy line however the message was typed', () {
      expect(AssistantSession.titleFor([user('  Help me\n\nrevise   for exams ')]), 'Help me revise for exams');
    });

    test('a long first message is shortened with an ellipsis', () {
      final title = AssistantSession.titleFor([user('word ' * 40)]);

      expect(title.length, lessThanOrEqualTo(AssistantSession.maxTitleLength));
      expect(title, endsWith('…'));
    });

    test('is empty when there is no student message yet', () {
      expect(AssistantSession.titleFor(const []), '');
    });
  });
}
