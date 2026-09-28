// Saved chats in the Spekooh Assistant: they save themselves, can be reopened
// and continued, deleted, and cleared, and live on this phone only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spekooh/data/assistant_history_store.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/offline_file_store.dart';
import 'package:spekooh/data/repositories/assistant_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/assistant_session.dart';
import 'package:spekooh/screens/assistant/assistant_chat_screen.dart';
import 'package:spekooh/screens/assistant/assistant_history_screen.dart';

import 'support/l10n_test_app.dart';

late AssistantHistoryStore _store;
late MockAssistantRepository _repo;

AssistantSession _saved(String id, String question, {DateTime? updatedAt}) => AssistantSession(
      id: id,
      title: question,
      createdAt: DateTime(2026, 9, 28, 8),
      updatedAt: updatedAt ?? DateTime(2026, 9, 28, 9),
      messages: [ChatMessage(role: 'user', content: question), const ChatMessage(role: 'assistant', content: 'An earlier answer.')],
    );

Future<void> _openChat(WidgetTester tester) async {
  await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: _repo, historyStore: _store)));
  await tester.pump();
}

Future<void> _ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byKey(const Key('assistantSendButton')));
  await tester.pumpAndSettle();
}

Future<void> _openHistory(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Chat history'));
  await tester.pumpAndSettle();
}

Future<void> _backFromHistory(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.chevronLeft).last);
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String tooltip) => tester.widget<IconButton>(find.widgetWithIcon(IconButton, tooltip == 'New chat' ? LucideIcons.squarePen : LucideIcons.history)).onPressed != null;

void main() {
  setUp(() {
    _store = AssistantHistoryStore(fileStore: InMemoryOfflineFileStore(), currentUserId: () => 'user-1');
    _repo = MockAssistantRepository()..mockReply = const ChatReply(content: 'Here is a real answer.', quotaRemaining: 10);
  });

  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('a chat saves itself once the assistant has replied', (tester) async {
    await _openChat(tester);

    await _ask(tester, 'Explain Newton\'s laws');

    final chats = await _store.list();
    expect(chats, hasLength(1));
    expect(chats.single.title, "Explain Newton's laws");
    expect(chats.single.messages.map((m) => m.role).toList(), ['user', 'assistant']);
  });

  testWidgets('carrying on in the same chat updates the one saved chat, it does not add another', (tester) async {
    await _openChat(tester);
    await _ask(tester, 'First question');

    await _ask(tester, 'A follow-up');

    final chats = await _store.list();
    expect(chats, hasLength(1));
    expect(chats.single.messages, hasLength(4));
    expect(chats.single.title, 'First question');
  });

  testWidgets('with nothing saved, the history says so and where chats are kept', (tester) async {
    await _openChat(tester);

    await _openHistory(tester);

    expect(find.text('Chat history'), findsOneWidget);
    expect(find.textContaining('saved on this phone only'), findsOneWidget);
  });

  testWidgets('the history lists saved chats with their size', (tester) async {
    await _store.save(_saved('a', 'Photosynthesis explained'));
    await _openChat(tester);

    await _openHistory(tester);

    expect(find.text('Photosynthesis explained'), findsOneWidget);
    expect(find.textContaining('2 messages'), findsOneWidget);
  });

  testWidgets('tapping a saved chat reopens it, and carrying on continues that same chat', (tester) async {
    await _store.save(_saved('a', 'Photosynthesis explained'));
    await _openChat(tester);
    await _openHistory(tester);

    await tester.tap(find.text('Photosynthesis explained'));
    await tester.pumpAndSettle();

    expect(find.text('An earlier answer.'), findsOneWidget);
    await _ask(tester, 'And what about respiration?');
    final chats = await _store.list();
    expect(chats, hasLength(1)); // continued, not duplicated
    expect(chats.single.messages, hasLength(4));
    expect(_repo.calls.single.map((m) => m.content).toList(), ['Photosynthesis explained', 'An earlier answer.', 'And what about respiration?']);
  });

  testWidgets('New chat starts fresh and keeps the previous chat in the history', (tester) async {
    await _openChat(tester);
    expect(_enabled(tester, 'New chat'), isFalse); // nothing to leave yet
    await _ask(tester, 'Chat one');
    expect(_enabled(tester, 'New chat'), isTrue);

    await tester.tap(find.byTooltip('New chat'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ask me anything about your schoolwork'), findsOneWidget); // a blank chat again
    await _ask(tester, 'Chat two');
    expect((await _store.list()).map((s) => s.title).toSet(), {'Chat one', 'Chat two'});
  });

  testWidgets('deleting a chat asks first, and cancelling keeps it', (tester) async {
    await _store.save(_saved('a', 'Keep me'));
    await _openChat(tester);
    await _openHistory(tester);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this chat?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Keep me'), findsOneWidget);
    expect(await _store.list(), hasLength(1));
  });

  testWidgets('confirming the delete removes it from this phone', (tester) async {
    await _store.save(_saved('a', 'Remove me'));
    await _openChat(tester);
    await _openHistory(tester);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Remove me'), findsNothing);
    expect(find.textContaining('saved on this phone only'), findsOneWidget);
    expect(await _store.list(), isEmpty);
  });

  testWidgets('deleting the chat that is open leaves a fresh chat, not a half-saved one', (tester) async {
    await _openChat(tester);
    await _ask(tester, 'Open chat');
    await _openHistory(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await _backFromHistory(tester);

    expect(find.text('Open chat'), findsNothing);
    expect(find.textContaining('Ask me anything about your schoolwork'), findsOneWidget);
    expect(await _store.list(), isEmpty);
  });

  testWidgets('Clear all removes every saved chat after confirming', (tester) async {
    await _store.save(_saved('a', 'One'));
    await _store.save(_saved('b', 'Two', updatedAt: DateTime(2026, 9, 29)));
    await _openChat(tester);
    await _openHistory(tester);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all saved chats?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await _store.list(), isEmpty);
    expect(find.text('Clear all'), findsNothing); // nothing left to clear
  });

  testWidgets('a failing store never stops the assistant from answering', (tester) async {
    final broken = AssistantHistoryStore(fileStore: _Unavailable(), currentUserId: () => 'user-1');
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: _repo, historyStore: broken)));
    await tester.pump();

    await _ask(tester, 'Still works?');

    expect(find.text('Here is a real answer.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the history screen is translated', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(AssistantHistoryScreen(store: _store)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Historique des discussions'), findsOneWidget);
    expect(find.textContaining('uniquement sur ce téléphone'), findsOneWidget);
  });
}

class _Unavailable implements OfflineFileStore {
  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) async => throw Exception('disk full');
  @override
  Future<List<int>?> readBytes(String relativePath) async => throw Exception('unreadable');
  @override
  Future<void> delete(String relativePath) async => throw Exception('unavailable');
  @override
  Future<String> absolutePathFor(String relativePath) async => '';
}
