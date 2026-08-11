import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/models/paper_entry.dart';
import 'package:spekooh/screens/home/home_screen.dart';
import 'package:spekooh/screens/home/logged_in_home_screen.dart';
import 'package:spekooh/theme/app_theme.dart';
import 'package:spekooh/main.dart';

import 'support/mock_repository_locator.dart';

void main() {
  testWidgets('HomeScreen (guest) shows an honest empty state when nothing is published yet', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: appTheme,
      home: HomeScreen(papersRepository: MockPapersRepository(), shopRepository: MockShopRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('No papers published yet — check back soon.'), findsOneWidget);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget); // real featured pamphlet from the mock
  });

  testWidgets('HomeScreen (guest) shows the real latest published paper when one exists', (tester) async {
    final seeded = PaperEntry(
      id: 7,
      year: 2025,
      system: null,
      track: '',
      status: 'PUBLISHED',
      fileUrl: null,
      createdAt: DateTime(2025, 1, 1),
      subjectTitle: 'Mathématiques',
      examTypeName: 'Baccalauréat',
    );
    PaperEntry? opened;
    await tester.pumpWidget(MaterialApp(
      theme: appTheme,
      home: HomeScreen(
        papersRepository: MockPapersRepository(seedPublished: [seeded]),
        shopRepository: MockShopRepository(),
        onOpenPaper: (p) => opened = p,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Mathématiques · Baccalauréat 2025'), findsOneWidget);

    await tester.tap(find.textContaining('Mathématiques · Baccalauréat 2025'));
    await tester.pump();
    expect(opened?.id, 7);
  });

  testWidgets('LoggedInHomeScreen builds with real profile/streak/daily-challenge data', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: appTheme,
      home: LoggedInHomeScreen(profileRepository: MockProfileRepository(), quizzesRepository: MockQuizzesRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget); // MockProfileRepository's real (if placeholder) name
    expect(find.text('Daily challenge'), findsOneWidget);
    expect(find.text('START A STREAK'), findsOneWidget); // MockQuizzesRepository starts at zero — honest, not fabricated
  });

  testWidgets('Full login flow: Settings -> Log in -> LoggedInHomeScreen on Home tab', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());

    await tester.ensureVisible(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    await tester.ensureVisible(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    // AuthSheet is now open (login mode: email field, then password field) — fill in and submit.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'test@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.text('Log in').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget); // MockProfileRepository's real (placeholder) name
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
  });
}
