import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/main.dart';

import 'support/mock_repository_locator.dart';

void main() {
  testWidgets('App boots and shows the guest Home tab with bottom nav', (WidgetTester tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Papers'), findsOneWidget);
    expect(find.text('Forum'), findsOneWidget);
    expect(find.text('Quizzes'), findsOneWidget);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
  });

  testWidgets('Tapping a bottom nav tab switches the active index', (WidgetTester tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());
    await tester.tap(find.text('Papers'));
    await tester.pump();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
  });
}
