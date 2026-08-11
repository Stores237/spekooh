import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/models/paper_entry.dart';
import 'package:spekooh/screens/papers/papers_screen.dart';
import 'package:spekooh/theme/app_theme.dart';

void main() {
  testWidgets('PapersScreen full drill-down: category (needs system+track) -> paper -> back all the way', (tester) async {
    PaperSelection? opened;
    final seededPaper = PaperEntry(
      id: 42,
      year: 2026,
      system: 'anglophone',
      track: 'Science',
      status: 'PUBLISHED',
      fileUrl: 'http://testserver/media/paper_submissions/2026/physics.pdf',
      createdAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(MaterialApp(
      theme: appTheme,
      home: PapersScreen(repository: MockPapersRepository(seedPublished: [seededPaper]), onOpenPaper: (p) => opened = p),
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
    await tester.pump(const Duration(milliseconds: 50)); // ...then the real getPapers() FutureBuilder

    // Step 6: real paper list, resolved subject header shown, seeded paper visible.
    expect(find.text('Physics'), findsWidgets);
    expect(find.textContaining('A Level 2026'), findsWidgets);

    // Tap the paper row -> onOpenPaper fires with the real PaperEntry attached.
    await tester.tap(find.textContaining('A Level 2026').first);
    await tester.pump();
    expect(opened, isNotNull);
    expect(opened!.subject.key, 'physics');
    expect(opened!.examType.name, 'A Level');
    expect(opened!.track, 'Science');
    expect(opened!.entry.id, 42);
    expect(opened!.entry.year, 2026);

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

  testWidgets('No papers submitted yet shows an honest empty state, not fabricated rows', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: PapersScreen(repository: MockPapersRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Primary'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('FSLC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.ensureVisible(find.text('Accounting'));
    await tester.tap(find.text('Accounting'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No papers yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
