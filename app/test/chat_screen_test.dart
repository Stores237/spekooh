import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/screens/papers/chat_screen.dart';

import 'support/l10n_test_app.dart';

void main() {
  testWidgets('shows the empty-state hint before anything is sent', (tester) async {
    await tester.pumpWidget(l10nTestApp(ChatScreen(paperId: 1, paperTitle: 'GCE O Level Biology 2024', repository: MockPapersRepository())));

    expect(find.textContaining('Ask me anything'), findsOneWidget);
    expect(find.text('GCE O Level Biology 2024'), findsOneWidget);
  });

  testWidgets('sending a message shows both bubbles and the real quota count', (tester) async {
    final repo = MockPapersRepository()..mockChatReply = const ChatReply(content: 'Photosynthesis makes food from light.', quotaRemaining: 12);
    await tester.pumpWidget(l10nTestApp(ChatScreen(paperId: 1, paperTitle: 'Bio 2024', repository: repo)));

    await tester.enterText(find.byType(TextField), 'Explain question 1');
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();

    expect(find.text('Explain question 1'), findsOneWidget);
    expect(find.text('Photosynthesis makes food from light.'), findsOneWidget);
    expect(find.text('12 free left today'), findsOneWidget);
    expect(repo.chatCalls, hasLength(1));
    expect(repo.chatCalls.single.single.content, 'Explain question 1');
  });

  testWidgets('a Pro user (no quota_remaining) shows no quota badge at all', (tester) async {
    final repo = MockPapersRepository()..mockChatReply = const ChatReply(content: 'A real reply.', quotaRemaining: null);
    await tester.pumpWidget(l10nTestApp(ChatScreen(paperId: 1, paperTitle: 'Bio 2024', repository: repo)));

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('free left today'), findsNothing);
  });

  testWidgets('an exhausted quota shows the upgrade banner and disables further input', (tester) async {
    var upgradeOpened = false;
    final repo = MockPapersRepository()..mockChatError = const ChatQuotaExceededException();
    await tester.pumpWidget(l10nTestApp(ChatScreen(paperId: 1, paperTitle: 'Bio 2024', repository: repo, onOpenPaywall: () => upgradeOpened = true)));

    await tester.enterText(find.byType(TextField), 'one more question');
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();

    expect(find.text("You've used today's free chat messages."), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);

    await tester.tap(find.text('Upgrade'));
    expect(upgradeOpened, isTrue);
  });

  testWidgets('a real network/server error shows a SnackBar, not a crash', (tester) async {
    final repo = MockPapersRepository()..mockChatError = Exception('boom');
    await tester.pumpWidget(l10nTestApp(ChatScreen(paperId: 1, paperTitle: 'Bio 2024', repository: repo)));

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't send that"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
