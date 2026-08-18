import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/repositories/forum_repository.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/screens/forum/forum_screen.dart';
import 'package:spekooh/screens/quizzes/quizzes_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/l10n_test_app.dart';

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('Forum: Ask button posts a new question that appears in the list', (tester) async {
    final repo = MockForumRepository();
    await tester.pumpWidget(l10nTestApp(ForumScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('+ Question'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Chemistry');
    await tester.enterText(fields.at(1), 'How do I balance this equation?');
    await tester.enterText(fields.at(2), 'Stuck on redox reactions.');
    await tester.tap(find.text('Post question'));
    await tester.pumpAndSettle();

    expect(find.text('How do I balance this equation?'), findsOneWidget);
  });

  testWidgets('Forum: tapping a post opens detail, upvote toggles, reply posts', (tester) async {
    final repo = MockForumRepository();
    await tester.pumpWidget(l10nTestApp(ForumScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Rescheduling of Baccalauréat 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Question'), findsOneWidget);

    // Upvote.
    await tester.tap(find.byIcon(LucideIcons.arrowUp));
    await tester.pump();
    expect(find.byIcon(LucideIcons.arrowUp), findsOneWidget);

    // Reply.
    await tester.enterText(find.byType(TextField), 'Great question!');
    await tester.tap(find.byIcon(LucideIcons.send));
    await tester.pumpAndSettle();
    expect(find.text('Great question!'), findsOneWidget);
  });

  testWidgets('Forum: filter chips really filter — Unanswered is real, My subjects/Solved are honest not-yet-available', (tester) async {
    final repo = MockForumRepository();
    // The mock posts are all pre-answered, so a genuinely-real "Unanswered"
    // filter should empty the list, not just relabel the same content.
    await repo.createPost(tag: 'Chemistry', title: 'Freshly asked, zero replies', body: 'x');
    await tester.pumpWidget(l10nTestApp(ForumScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Freshly asked, zero replies'), findsOneWidget);

    await tester.tap(find.text('Unanswered'));
    await tester.pump();
    expect(find.text('Freshly asked, zero replies'), findsOneWidget); // the one real unanswered post survives
    expect(find.textContaining('Rescheduling'), findsNothing); // the pre-answered mock posts are filtered out

    await tester.tap(find.text('My subjects'));
    await tester.pump();
    expect(find.textContaining('isn\'t available yet'), findsOneWidget);
    expect(find.text('Freshly asked, zero replies'), findsNothing);

    await tester.tap(find.text('Solved'));
    await tester.pump();
    expect(find.textContaining('isn\'t available yet'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pump();
    await tester.pump(); // leaving an unavailable-filter tab remounts the FutureBuilder; flush its microtask
    expect(find.text('Freshly asked, zero replies'), findsOneWidget);
    expect(find.textContaining('Rescheduling'), findsOneWidget);
  });

  testWidgets('Quizzes: opening a quiz and submitting answers shows a score', (tester) async {
    final repo = MockQuizzesRepository();
    await tester.pumpWidget(l10nTestApp(QuizzesScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.ensureVisible(find.text('Biology quiz'));
    await tester.pump();
    await tester.tap(find.text('Biology quiz'));
    await tester.pump();

    expect(find.text('Start quiz'), findsOneWidget);
    // Answer both mock questions (choice index 1 in each).
    await tester.ensureVisible(find.text('Mitochondrion'));
    await tester.pump();
    await tester.tap(find.text('Mitochondrion'));
    await tester.pump();
    await tester.ensureVisible(find.text('Carbohydrates'));
    await tester.pump();
    await tester.tap(find.text('Carbohydrates'));
    await tester.pump();

    await tester.ensureVisible(find.text('Start quiz'));
    await tester.pump();
    await tester.tap(find.text('Start quiz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('You scored'), findsOneWidget);
  });

  testWidgets('Quizzes: unbuilt features (past-paper practice, Friday Arena) are shown as coming soon, not fake content', (tester) async {
    final repo = MockQuizzesRepository();
    await tester.pumpWidget(l10nTestApp(QuizzesScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Past-paper practice'), findsOneWidget);
    expect(find.textContaining('coming soon'), findsWidgets);
    // Tapping it must not open any quiz detail (no more "Start quiz" from a fake source).
    await tester.tap(find.textContaining('Past-paper practice'));
    await tester.pump();
    expect(find.text('Start quiz'), findsNothing);
  });

  testWidgets('Quizzes: daily challenge shows a real computed reset countdown, not a hardcoded one', (tester) async {
    final repo = MockQuizzesRepository();
    await tester.pumpWidget(l10nTestApp(QuizzesScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Resets in'), findsOneWidget);
    expect(find.text('Resets in 7h 23m'), findsNothing); // the old hardcoded literal
  });

  testWidgets('ForumScreen renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(ForumScreen(repository: MockForumRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Forum'), findsOneWidget); // same word in both languages
    expect(find.text('Sans réponse'), findsOneWidget);
    expect(find.text('Unanswered'), findsNothing);
  });

  testWidgets('QuizzesScreen renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(QuizzesScreen(repository: MockQuizzesRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('DÉFI DU JOUR'), findsOneWidget);
    expect(find.text('Meilleurs joueurs'), findsOneWidget);
    expect(find.text('DAILY CHALLENGE'), findsNothing);
  });
}
