import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/widgets/subject_card.dart';

/// Real, contributor-typed subject names previously overflowed past their
/// own card into whatever sat below it — every card in the grid shares one
/// fixed childAspectRatio, so a long name broke the whole grid's layout
/// (found from a live screenshot, 2026-08-28: "Research méthodologie and
/// scientific writing" visibly spilled out of its card onto the AI
/// assistant FAB below it).
void main() {
  // ~158px wide, ~172px tall — matches a real narrow-ish phone's actual
  // grid cell (crossAxisCount 2, childAspectRatio 0.92; see
  // papers_screen.dart's subject-step GridView), not an arbitrary size.
  Widget cardIn(String title) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 158,
            height: 172,
            child: SubjectCard(
              icon: const Icon(Icons.book),
              title: title,
              subtitle: 'Épreuves + corrigés',
              badgeText: 'Épreuves',
            ),
          ),
        ),
      );

  testWidgets('the exact reported title fits without overflowing its card', (tester) async {
    await tester.pumpWidget(cardIn('Research méthodologie and scientific writing'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a long subject title is capped, not left to overflow the card', (tester) async {
    const title = 'Fondation of data science and programming of data science';
    await tester.pumpWidget(cardIn(title));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final titleWidget = tester.widget<Text>(find.text(title));
    expect(titleWidget.maxLines, 2);
    expect(titleWidget.overflow, TextOverflow.ellipsis);
  });

  testWidgets('a short title still renders normally', (tester) async {
    await tester.pumpWidget(cardIn('Chemistry'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Chemistry'), findsOneWidget);
  });
}
