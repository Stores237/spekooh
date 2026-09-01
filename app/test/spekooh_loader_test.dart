import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/theme/app_colors.dart';
import 'package:spekooh/widgets/spekooh_loader.dart';

/// The one branded loading treatment for a page/section waiting on real
/// data (2026-09-01, owner-requested) — replaces every bare default-gray
/// CircularProgressIndicator so a loading screen looks like a deliberate
/// part of the app, not unfinished scaffolding.
void main() {
  testWidgets('renders a gold circular indicator, not the bare Material default', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SpekoohLoader()));

    final indicator = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
    expect(indicator.color, AppColors.gold500);
  });

  testWidgets('defaults to a 32px indicator, but a caller can size it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SpekoohLoader()));
    expect(tester.getSize(find.byType(CircularProgressIndicator)).width, 32);

    await tester.pumpWidget(const MaterialApp(home: SpekoohLoader(size: 48)));
    expect(tester.getSize(find.byType(CircularProgressIndicator)).width, 48);
  });
}
