import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/widgets/phone_number_field.dart';

import 'support/l10n_test_app.dart';

void main() {
  testWidgets('shows the real country code, an XXX placeholder (not a real-looking example), and accepts real digits', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(l10nTestApp(Scaffold(body: PhoneNumberField(controller: controller))));
    await tester.pump();

    expect(find.text('+237'), findsOneWidget);
    expect(find.text('670 12 34 56'), findsNothing); // the old, real-looking sample number
    expect(find.text('XXX XX XX XX'), findsOneWidget); // the real hint text

    await tester.enterText(find.byType(TextField), '670123456');
    expect(controller.text, '670123456');
  });

  testWidgets('the country picker opens on tap, with the one real supported country', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(l10nTestApp(Scaffold(body: PhoneNumberField(controller: controller))));
    await tester.pump();

    await tester.tap(find.byKey(const Key('phoneCountryPicker')));
    await tester.pumpAndSettle();

    expect(find.text('Cameroon'), findsOneWidget);
    expect(find.text('🇨🇲'), findsWidgets); // once in the field, once in the sheet's own row
  });

  testWidgets('a real error message shows below the field when one is passed', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(l10nTestApp(Scaffold(body: PhoneNumberField(controller: controller, error: 'Enter your MTN MoMo or Orange Money number.'))));
    await tester.pump();

    expect(find.text('Enter your MTN MoMo or Orange Money number.'), findsOneWidget);
  });
}
