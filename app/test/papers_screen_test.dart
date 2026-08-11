import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/screens/papers/papers_screen.dart';
import 'package:spekooh/theme/app_theme.dart';

void main() {
  testWidgets('PapersScreen full drill-down: category (needs system+track) -> paper -> back all the way', (tester) async {
    PaperSelection? opened;
    await tester.pumpWidget(MaterialApp(
      theme: appTheme,
      home: PapersScreen(repository: MockPapersRepository(), onOpenPaper: (p) => opened = p),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);

    // Step 1: category grid — Secondary requires a system step.
    expect(find.text('Past papers'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
    await tester.tap(find.text('Secondary'));
    await tester.pump();

    // Step 2: system (synchronous, no FutureBuilder).
    expect(find.text('Secondary — choose system'), findsOneWidget);
    await tester.tap(find.text('Anglophone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50)); // exam-type FutureBuilder

    // Step 3: exam type — A Level requires a track step.
    expect(find.text('Secondary · Anglophone'), findsOneWidget);
    expect(find.text('A Level'), findsOneWidget);
    await tester.tap(find.text('A Level'));
    await tester.pump();

    // Step 4: track (synchronous).
    expect(find.text('A Level — choose track'), findsOneWidget);
    await tester.tap(find.text('Science'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50)); // subject FutureBuilder

    // Step 5: subject (English exam type -> subjectsEn list).
    expect(find.text('Physics'), findsOneWidget);
    await tester.ensureVisible(find.text('Physics'));
    await tester.pump();
    await tester.tap(find.text('Physics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50)); // paperList's subject-lookup FutureBuilder

    // Step 6: paper-by-year list, resolved subject header shown.
    expect(find.text('Physics'), findsWidgets);
    expect(find.textContaining('A Level 2026'), findsWidgets);

    // Tap the first paper row -> onOpenPaper fires with a fully resolved selection.
    await tester.tap(find.textContaining('A Level 2026').first);
    await tester.pump();
    expect(opened, isNotNull);
    expect(opened!.subject.key, 'physics');
    expect(opened!.examType.name, 'A Level');
    expect(opened!.track, 'Science');
    expect(opened!.year, 2026);

    // Step back from paperList -> clears subject only, returns to subject step.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('A Level'), findsOneWidget); // subject-step header shows examType name
    expect(find.text('Science'), findsOneWidget); // ...and the track as subtitle
  });

  testWidgets('Category with no system/track requirement goes straight to exam-type then subject step', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: PapersScreen(repository: MockPapersRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Primary'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50)); // exam-type FutureBuilder

    // Primary has no system step -> straight to exam types; FSLC has no track.
    expect(find.text('FSLC'), findsOneWidget);
    await tester.tap(find.text('FSLC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50)); // subject FutureBuilder

    expect(find.text('Accounting'), findsOneWidget); // English subject list (FSLC is Anglophone)
    expect(tester.takeException(), isNull);
  });
}
