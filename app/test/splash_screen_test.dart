import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/shell/splash_screen.dart';
import 'package:spekooh/widgets/heritage_pattern_strip.dart';

void main() {
  testWidgets('shows the logo and the subtle heritage pattern strip, then hands off to child', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashScreen(child: const Text('Real app content'))));
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(HeritagePatternStrip), findsOneWidget);
    expect(find.text('Real app content'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Real app content'), findsOneWidget);
    expect(find.byType(HeritagePatternStrip), findsNothing);
  });
}
