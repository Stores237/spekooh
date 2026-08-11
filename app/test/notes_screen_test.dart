import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/main.dart';

import 'support/mock_repository_locator.dart';

void main() {
  testWidgets('Notes opens from Home and back button returns', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());

    await tester.ensureVisible(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Mechanics — Newton’s Laws'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Guest'), findsOneWidget);
  });
}
