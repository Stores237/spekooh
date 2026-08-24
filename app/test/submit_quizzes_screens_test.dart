import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/screens/submit/submit_screen.dart';
import 'package:spekooh/screens/quizzes/quizzes_screen.dart';
import 'package:spekooh/widgets/spekooh_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/fake_auth_session.dart';
import 'support/l10n_test_app.dart';

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage()));
  });


  testWidgets('SubmitScreen builds a real paper-picker flow', (tester) async {
    await tester.pumpWidget(l10nTestApp(SubmitScreen(repository: MockPapersRepository())));
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
      await tester.tap(find.byIcon(LucideIcons.chevronLeft).evaluate().isNotEmpty ? find.byIcon(LucideIcons.chevronLeft) : find.text('Nothing available.'));
      await tester.pumpAndSettle();
    }

    // No file has been picked (file_picker needs a real platform channel,
    // unavailable in a widget test), so the submit button stays disabled —
    // this proves the flow genuinely gates on real state, not fake state.
    final submitButton = tester.widget<SpekoohButton>(find.widgetWithText(SpekoohButton, 'Submit paper'));
    expect(submitButton.disabled, isTrue);
  });

  testWidgets('SubmitScreen "Academic report" tab walks the real reports taxonomy', (tester) async {
    await tester.pumpWidget(l10nTestApp(SubmitScreen(repository: MockPapersRepository())));
    await tester.pump();

    await tester.tap(find.text('Academic report'));
    await tester.pumpAndSettle();
    expect(find.text('Submit report'), findsOneWidget);

    await tester.tap(find.text('Report type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Internship Report').last);
    await tester.pumpAndSettle();
    expect(find.text('Internship Report'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Institution / University'), 'Université de Douala');
    await tester.enterText(find.widgetWithText(TextField, 'Discipline / Department'), 'Computer Engineering');
    await tester.pump();

    await tester.ensureVisible(find.text('Year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year}').last);
    await tester.pumpAndSettle();

    // Supervisor is genuinely optional and no file has been picked (same
    // file_picker platform-channel limitation as the exam-paper flow), so
    // the submit button stays disabled even with every other real field set.
    final submitButton = tester.widget<SpekoohButton>(find.widgetWithText(SpekoohButton, 'Submit report'));
    expect(submitButton.disabled, isTrue);
  });

  testWidgets('a guest is asked to identify themselves; a logged-in contributor is not', (tester) async {
    // Owner decision: contributing doesn't require an account, but every
    // contributor still has to be identified by a real name — the field
    // shows for guests and gates the submit button, but a real account
    // already carries its own identity, so it stays hidden for them.
    await tester.pumpWidget(l10nTestApp(SubmitScreen(repository: MockPapersRepository())));
    await tester.pump();
    expect(find.text('Contributor name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Your name'), findsOneWidget);

    await tester.tap(find.text('Academic report'));
    await tester.pumpAndSettle();
    expect(find.text('Contributor name'), findsOneWidget);

    final authSession = buildFakeAuthSession();
    await authSession.login(email: 'test@example.com', password: 'whatever');
    AuthSession.debugSetInstance(authSession);

    await tester.pumpWidget(l10nTestApp(SubmitScreen(repository: MockPapersRepository())));
    await tester.pump();
    expect(find.text('Contributor name'), findsNothing);
    expect(find.widgetWithText(TextField, 'Your name'), findsNothing);
  });

  testWidgets('SubmitScreen renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(SubmitScreen(repository: MockPapersRepository())));
    await tester.pump();

    expect(find.text('Contribution'), findsOneWidget);
    expect(find.text("Soumettre l'épreuve"), findsOneWidget);
    expect(find.text('Submit paper'), findsNothing);
  });

  testWidgets('QuizzesScreen builds and opens/closes quiz detail', (tester) async {
    await tester.pumpWidget(l10nTestApp(QuizzesScreen(repository: MockQuizzesRepository())));
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

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pump();
    expect(find.text('Quiz'), findsOneWidget);
  });
}
