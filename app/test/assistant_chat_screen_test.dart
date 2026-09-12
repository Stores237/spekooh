import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/assistant_repository.dart';
import 'package:spekooh/screens/assistant/assistant_chat_screen.dart';

import 'support/l10n_test_app.dart';

void main() {
  testWidgets('shows the empty-state hint and real tappable suggested prompts before anything is sent', (tester) async {
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: MockAssistantRepository())));

    expect(find.textContaining('Ask me anything about your schoolwork'), findsOneWidget);
    expect(find.text('Explain a hard Physics topic'), findsOneWidget);
    expect(find.text('Give me 5 Maths practice questions'), findsOneWidget);
    expect(find.text('Help me plan a study schedule'), findsOneWidget);
  });

  testWidgets('tapping a suggested prompt sends it immediately — a real action now, not dead text', (tester) async {
    final repo = MockAssistantRepository()..mockReply = const ChatReply(content: 'Sure, let\'s talk Physics.', quotaRemaining: 4);
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: repo)));

    await tester.tap(find.text('Explain a hard Physics topic'));
    await tester.pumpAndSettle();

    expect(find.text('Explain a hard Physics topic'), findsOneWidget); // now the user's own chat bubble
    expect(find.text('Sure, let\'s talk Physics.'), findsOneWidget);
    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.single.content, 'Explain a hard Physics topic');
  });

  testWidgets('typing and sending a real message shows both bubbles and the real quota count', (tester) async {
    final repo = MockAssistantRepository()..mockReply = const ChatReply(content: 'A study plan for you: ...', quotaRemaining: 12);
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: repo)));

    await tester.enterText(find.byType(TextField), 'Help me revise for my exam');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.text('Help me revise for my exam'), findsOneWidget);
    expect(find.text('A study plan for you: ...'), findsOneWidget);
    expect(find.text('12 free left today'), findsOneWidget);
    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.single.content, 'Help me revise for my exam');
  });

  testWidgets('a Pro user (no quota_remaining) shows no quota badge at all', (tester) async {
    final repo = MockAssistantRepository()..mockReply = const ChatReply(content: 'A real reply.', quotaRemaining: null);
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: repo)));

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('free left today'), findsNothing);
  });

  testWidgets('an exhausted quota (shared with the per-paper chat) shows the upgrade banner and disables further input', (tester) async {
    var upgradeOpened = false;
    final repo = MockAssistantRepository()..mockError = const ChatQuotaExceededException();
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: repo, onOpenPaywall: () => upgradeOpened = true)));

    await tester.enterText(find.byType(TextField), 'one more question');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.text("You've used today's free chat messages."), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);

    await tester.tap(find.text('Upgrade'));
    expect(upgradeOpened, isTrue);
  });

  testWidgets('a real network/server error shows a SnackBar, not a crash', (tester) async {
    final repo = MockAssistantRepository()..mockError = Exception('boom');
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: repo)));

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't send that"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a real multi-chunk stream builds the same bubble in place, not several bubbles', (tester) async {
    final repo = MockAssistantRepository()
      ..mockStreamDeltas = ['Sure, ', 'here is ', 'a study ', 'plan.']
      ..mockReply = const ChatReply(content: 'unused — mockStreamDeltas wins', quotaRemaining: 9);
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: repo)));

    await tester.enterText(find.byType(TextField), 'Help me plan a study schedule');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.text('Sure, here is a study plan.'), findsOneWidget);
    expect(find.text('9 free left today'), findsOneWidget);
  });

  testWidgets('a mid-stream error frame keeps the partial reply on screen and shows a SnackBar', (tester) async {
    final repo = MockAssistantRepository()
      ..mockStreamDeltas = ['Here is a partial plan, ']
      ..mockStreamErrorDetail = 'AI chat is busy right now. Try again in a moment.';
    await tester.pumpWidget(l10nTestApp(AssistantChatScreen(repository: repo)));

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.text('Here is a partial plan, '), findsOneWidget);
    expect(find.textContaining('busy right now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
