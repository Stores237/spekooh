import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/screens/submit/submit_screen.dart';
import 'package:spekooh/screens/quizzes/quizzes_screen.dart';
import 'package:spekooh/theme/app_theme.dart';

void main() {
  testWidgets('SubmitScreen builds, switches type, and completes the flow', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: const SubmitScreen()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Submit paper'), findsOneWidget);

    await tester.tap(find.text('Academic report'));
    await tester.pump();
    expect(find.text('Submit report'), findsOneWidget);

    await tester.ensureVisible(find.text('Submit report'));
    await tester.pump();
    await tester.tap(find.text('Submit report'));
    await tester.pump();
    expect(find.text('Contribution received'), findsOneWidget);

    await tester.tap(find.text('Submit another'));
    await tester.pump();
    expect(find.text('Contribution'), findsOneWidget);
  });

  testWidgets('QuizzesScreen builds and opens/closes quiz detail', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: QuizzesScreen(repository: MockQuizzesRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Biology quiz'), findsOneWidget);

    await tester.ensureVisible(find.text('Biology quiz'));
    await tester.pump();
    await tester.tap(find.text('Biology quiz'));
    await tester.pump(); // resolves the async getQuizDetail(id) lookup — now opens its own detail, not the old shared hardcoded one
    expect(find.text('Biology quiz'), findsOneWidget);
    expect(find.text('Start quiz'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(find.text('Quiz'), findsOneWidget);
  });
}
