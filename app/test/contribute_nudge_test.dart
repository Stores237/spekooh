import 'package:flutter_test/flutter_test.dart';

import 'package:spekooh/data/repository_locator.dart';
import 'package:spekooh/main.dart';
import 'package:spekooh/shell/root_shell.dart';

import 'support/mock_repository_locator.dart';

void main() {
  tearDown(() {
    RootShellState.debugShowContributeNudge = true;
  });

  testWidgets('Contribute nudge shows on launch, dismiss closes it without navigating', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300)); // clears SplashScreen's timed handoff to RootShell
    await tester.pump(); // flushes the post-frame callback that opens the dialog

    expect(find.text('Help other students'), findsOneWidget);

    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();

    expect(find.text('Help other students'), findsNothing);
    expect(find.text('Guest'), findsOneWidget); // still on Home, guest untouched
  });

  testWidgets('Contribute nudge "Contribute now" closes it and switches to the Submit tab', (tester) async {
    RepositoryLocator.debugSetInstance(buildMockRepositoryLocator());
    await tester.pumpWidget(const SpekoohApp());
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    await tester.tap(find.text('Contribute now'));
    await tester.pumpAndSettle();

    expect(find.text('Help other students'), findsNothing);
    expect(find.text('Contribution'), findsOneWidget); // SubmitScreen's own title
  });
}
