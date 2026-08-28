import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/widgets/bottom_nav.dart';

/// The real bottom nav's flanking labels are genuinely asymmetric — the
/// French locale in particular ("Accueil"/"Épreuves" on the left vs
/// "Forum"/"Quiz" on the right) runs noticeably wider on one side. A flat
/// Row with MainAxisAlignment.spaceBetween distributes equal *gaps*, not
/// equal *halves*, so unequal label widths visibly pushed the raised
/// center button off true center (found from a live screenshot,
/// 2026-08-28: it sat right of center in exactly this asymmetric case).
void main() {
  Widget navWith({required List<SpekoohNavItem> items, required int active, required ValueChanged<int> onChanged}) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BottomNav(items: items, active: active, onChanged: onChanged),
      ),
    );
  }

  final asymmetricItems = [
    const SpekoohNavItem(icon: Icon(Icons.home), label: 'Accueil'), // long French label
    const SpekoohNavItem(icon: Icon(Icons.description), label: 'Épreuves'), // longer still
    const SpekoohNavItem(icon: Icon(Icons.upload), center: true),
    const SpekoohNavItem(icon: Icon(Icons.forum), label: 'Forum'), // short
    const SpekoohNavItem(icon: Icon(Icons.bolt), label: 'Quiz'), // shortest
  ];

  testWidgets('the center button sits at the true horizontal center even with asymmetric label widths', (tester) async {
    await tester.pumpWidget(navWith(items: asymmetricItems, active: 0, onChanged: (_) {}));
    await tester.pump();

    final barWidth = tester.getSize(find.byType(BottomNav)).width;
    final centerButtonX = tester.getCenter(find.byIcon(Icons.upload)).dx;
    final barLeftX = tester.getTopLeft(find.byType(BottomNav)).dx;
    final trueCenterX = barLeftX + barWidth / 2;

    // A few px of tolerance for icon-glyph rendering, not the several-dozen
    // px the old spaceBetween layout was off by.
    expect((centerButtonX - trueCenterX).abs(), lessThan(4));
  });

  testWidgets('tapping each tab still reports the right index after the layout change', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(navWith(items: asymmetricItems, active: 0, onChanged: tapped.add));

    await tester.tap(find.text('Accueil'));
    await tester.tap(find.text('Épreuves'));
    await tester.tap(find.byIcon(Icons.upload));
    await tester.tap(find.text('Forum'));
    await tester.tap(find.text('Quiz'));

    expect(tapped, [0, 1, 2, 3, 4]);
  });
}
