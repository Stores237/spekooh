import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/sheets/scan_pages_sheet.dart';
import 'package:spekooh/widgets/spekooh_button.dart';

import 'support/l10n_test_app.dart';

/// A real, minimal, decodable 1x1 transparent PNG — DecorationImage/
/// MemoryImage actually try to decode the bytes, so a placeholder like
/// `Uint8List(4)` would surface a real image-decode error in these tests.
final _onePixelPng = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196,
  137, 0, 0, 0, 11, 73, 68, 65, 84, 120, 156, 99, 250, 207, 0, 0, 2, 8, 1, 2, 5, 154, 6, 122, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130,
]);

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('ScanPagesSheet renders one thumbnail per initial page, singular label at 1 page', (tester) async {
    await tester.pumpWidget(l10nTestApp(ScanPagesSheet(initialPages: [_onePixelPng])));
    await tester.pump();

    expect(find.text('Use 1 page'), findsOneWidget);
    expect(find.byKey(const Key('scanRemovePageButton_0')), findsOneWidget);
    expect(find.byKey(const Key('scanRemovePageButton_1')), findsNothing);
  });

  testWidgets('ScanPagesSheet: removing a page updates the count and the button label', (tester) async {
    await tester.pumpWidget(l10nTestApp(ScanPagesSheet(initialPages: [_onePixelPng, _onePixelPng, _onePixelPng])));
    await tester.pump();

    expect(find.text('Use 3 pages'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scanRemovePageButton_1')));
    await tester.pump();

    expect(find.text('Use 2 pages'), findsOneWidget);
    // What was page 3 (index 2) shifts down to index 1 after the removal.
    expect(find.byKey(const Key('scanRemovePageButton_1')), findsOneWidget);
    expect(find.byKey(const Key('scanRemovePageButton_2')), findsNothing);
  });

  testWidgets('ScanPagesSheet: removing every page disables the button instead of allowing an empty submission', (tester) async {
    await tester.pumpWidget(l10nTestApp(ScanPagesSheet(initialPages: [_onePixelPng])));
    await tester.pump();

    await tester.tap(find.byKey(const Key('scanRemovePageButton_0')));
    await tester.pump();

    final button = tester.widget<SpekoohButton>(find.byType(SpekoohButton));
    expect(button.disabled, isTrue);
  });

  testWidgets('ScanPagesSheet: the "+" tile is a safe no-op when the scanner plugin is unavailable (as in this test environment)', (tester) async {
    await tester.pumpWidget(l10nTestApp(ScanPagesSheet(initialPages: [_onePixelPng])));
    await tester.pump();

    await tester.tap(find.byKey(const Key('scanAddPageButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // MissingPluginException is caught the same way a user cancelling is —
    // no crash, no page added, no permanent stuck "scanning" spinner.
    expect(find.text('Use 1 page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ScanPagesSheet renders in French once that locale is active', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(ScanPagesSheet(initialPages: [_onePixelPng])));
    await tester.pump();

    expect(find.text('Utiliser 1 page'), findsOneWidget);
    expect(find.text('Scanner des pages'), findsOneWidget);
  });
}
