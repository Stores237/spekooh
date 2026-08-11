import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/forum_repository.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/screens/forum/forum_screen.dart';
import 'package:spekooh/screens/quizzes/quizzes_screen.dart';
import 'package:spekooh/theme/app_theme.dart';

void main() {
  testWidgets('Forum: Ask button posts a new question that appears in the list', (tester) async {
    final repo = MockForumRepository();
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: ForumScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('+ Ask'));
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
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: ForumScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Rescheduling of Baccalauréat 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Question'), findsOneWidget);

    // Upvote.
    await tester.tap(find.byIcon(Icons.arrow_upward_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    // Reply.
    await tester.enterText(find.byType(TextField), 'Great question!');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Great question!'), findsOneWidget);
  });

  testWidgets('Quizzes: opening a quiz and submitting answers shows a score', (tester) async {
    final repo = MockQuizzesRepository();
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: QuizzesScreen(repository: repo)));
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
}
