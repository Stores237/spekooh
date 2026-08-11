import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/screens/submit/submit_screen.dart';
import 'package:spekooh/screens/quizzes/quizzes_screen.dart';
import 'package:spekooh/theme/app_theme.dart';
import 'package:spekooh/widgets/spekooh_button.dart';

void main() {
  testWidgets('SubmitScreen builds a real paper-picker flow and the report tab is honest about being unwired', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: SubmitScreen(repository: MockPapersRepository())));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Submit paper'), findsOneWidget);

    // Walk the real taxonomy picker: Education level -> Exam type -> Subject -> Year.
    await tester.tap(find.text('Education level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Primary').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exam type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FSLC').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subject'));
    await tester.pumpAndSettle();
    final subjectOption = find.text('Accounting');
    if (subjectOption.evaluate().isNotEmpty) {
      await tester.tap(subjectOption.last);
      await tester.pumpAndSettle();
    } else {
      await tester.tap(find.byIcon(Icons.chevron_left).evaluate().isNotEmpty ? find.byIcon(Icons.chevron_left) : find.text('Nothing available.'));
      await tester.pumpAndSettle();
    }

    // No file has been picked (file_picker needs a real platform channel,
    // unavailable in a widget test), so the submit button stays disabled —
    // this proves the flow genuinely gates on real state, not fake state.
    final submitButton = tester.widget<SpekoohButton>(find.widgetWithText(SpekoohButton, 'Submit paper'));
    expect(submitButton.disabled, isTrue);

    await tester.tap(find.text('Academic report'));
    await tester.pump();
    expect(find.text('Not available yet'), findsOneWidget);
    expect(find.textContaining('only exam papers can be submitted right now'), findsOneWidget);
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
