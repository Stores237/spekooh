import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/debug/widget_gallery_screen.dart';
import 'package:spekooh/theme/app_theme.dart';

void main() {
  testWidgets('WidgetGalleryScreen builds with no exceptions', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: const WidgetGalleryScreen()));
    await tester.pump();
    final exception = tester.takeException();
    if (exception != null) {
      // ignore: avoid_print
      print('EXCEPTION DURING BUILD: $exception');
    }
    expect(exception, isNull);
  });
}
