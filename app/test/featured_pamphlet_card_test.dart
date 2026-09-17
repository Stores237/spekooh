import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/models/pamphlet.dart';
import 'package:spekooh/widgets/featured_pamphlet_card.dart';

import 'support/l10n_test_app.dart';

const _pamphlet = Pamphlet(
  title: 'Advance Level Philosophy Pamphlet',
  partner: 'Librairie Centrale',
  priceFcfa: '7,500',
  description: '11 years of past questions + solutions.',
  subjectTitle: 'Philosophy',
  academicLevel: 'A Level',
);

void main() {
  testWidgets('shows the real title, subject/level labels, description, price, and a Buy button', (tester) async {
    await tester.pumpWidget(l10nTestApp(Scaffold(body: FeaturedPamphletCard(pamphlet: _pamphlet))));

    expect(find.text('Advance Level Philosophy Pamphlet'), findsOneWidget);
    expect(find.text('PHILOSOPHY'), findsOneWidget);
    expect(find.text('A Level'), findsOneWidget);
    expect(find.text('11 years of past questions + solutions.'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('7,500')),
      findsOneWidget,
    );
    expect(find.text('Buy'), findsOneWidget);
  });

  testWidgets('tapping the card or the Buy button both trigger onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(l10nTestApp(Scaffold(body: FeaturedPamphletCard(pamphlet: _pamphlet, onTap: () => tapped++))));

    await tester.tap(find.text('Buy'));
    expect(tapped, 1);
  });

  testWidgets('omits the description line when there is none', (tester) async {
    const noDescription = Pamphlet(title: 'GCE A Level Further Maths Pack', partner: 'Presbook Bookshop', priceFcfa: '6,000');
    await tester.pumpWidget(l10nTestApp(Scaffold(body: FeaturedPamphletCard(pamphlet: noDescription))));

    expect(find.text('GCE A Level Further Maths Pack'), findsOneWidget);
    expect(find.text('11 years of past questions + solutions.'), findsNothing);
  });

  testWidgets('renders no Image widget at all for the gold placeholder path (no cover uploaded yet)', (tester) async {
    await tester.pumpWidget(l10nTestApp(Scaffold(body: FeaturedPamphletCard(pamphlet: _pamphlet))));

    expect(find.byType(Image), findsNothing);
    expect(find.text('PHILOSOPHY'), findsOneWidget);
  });

  testWidgets('wires the real uploaded cover URL into a network image once one exists', (tester) async {
    const coverUrl = 'https://example.com/pamphlets/philosophy-cover.jpg';
    const withCover = Pamphlet(
      title: 'Advance Level Philosophy Pamphlet',
      partner: 'Librairie Centrale',
      priceFcfa: '7,500',
      subjectTitle: 'Philosophy',
      coverImageUrl: coverUrl,
    );
    await tester.pumpWidget(l10nTestApp(Scaffold(body: FeaturedPamphletCard(pamphlet: withCover))));

    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage && (w.image as NetworkImage).url == coverUrl),
      findsOneWidget,
    );
  });
}
