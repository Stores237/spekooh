import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/screens/legal/faq_content.dart';
import 'package:spekooh/screens/legal/faq_screen.dart';

import 'support/l10n_test_app.dart';

/// Owner-requested (2026-09-02), reached from Settings' new "FAQ" row.
/// Real answers only — see faq_content.dart's own header for exactly what
/// backs each one, same discipline as privacy_policy_content.dart.
void main() {
  testWidgets('shows every real question collapsed, none of the answers, until tapped', (tester) async {
    await tester.pumpWidget(l10nTestApp(const FaqScreen()));
    await tester.pump();

    for (final entry in faqEntries) {
      expect(find.text(entry.question), findsOneWidget);
    }
    // Real answer text stays hidden until its own question is tapped —
    // nothing here is dumped as one flat wall of text.
    expect(find.text(faqEntries.first.answer), findsNothing);
  });

  testWidgets('tapping a question reveals its own answer, and only that one', (tester) async {
    await tester.pumpWidget(l10nTestApp(const FaqScreen()));
    await tester.pump();

    await tester.tap(find.text(faqEntries[0].question));
    await tester.pumpAndSettle();

    expect(find.text(faqEntries[0].answer), findsOneWidget);
    expect(find.text(faqEntries[1].answer), findsNothing);
  });

  testWidgets('tapping an already-expanded question collapses it again', (tester) async {
    await tester.pumpWidget(l10nTestApp(const FaqScreen()));
    await tester.pump();

    await tester.tap(find.text(faqEntries[0].question));
    await tester.pumpAndSettle();
    expect(find.text(faqEntries[0].answer), findsOneWidget);

    await tester.tap(find.text(faqEntries[0].question));
    await tester.pumpAndSettle();
    expect(find.text(faqEntries[0].answer), findsNothing);
  });

  testWidgets('multiple questions can stay expanded at once, independently', (tester) async {
    await tester.pumpWidget(l10nTestApp(const FaqScreen()));
    await tester.pump();

    await tester.tap(find.text(faqEntries[0].question));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(faqEntries[2].question));
    await tester.tap(find.text(faqEntries[2].question));
    await tester.pumpAndSettle();

    expect(find.text(faqEntries[0].answer), findsOneWidget);
    expect(find.text(faqEntries[2].answer), findsOneWidget);
    expect(find.text(faqEntries[1].answer), findsNothing);
  });
}
