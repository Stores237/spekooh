import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/widgets/heritage_pattern_strip.dart';

void main() {
  testWidgets('paints without exception and stays subtle by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HeritagePatternStrip())));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
    // "less presence... not aggressive" (owner, 2026-09-12) — a real
    // ceiling check, not just that some value was passed. Comfortably
    // under half-opacity: a background texture, not a foreground border.
    expect(opacityWidget.opacity, lessThan(0.3));
  });

  testWidgets('a custom opacity/height is honored', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HeritagePatternStrip(height: 40, opacity: 0.5))));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacityWidget.opacity, 0.5);
    final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
    expect(sizedBox.height, 40);
  });
}
