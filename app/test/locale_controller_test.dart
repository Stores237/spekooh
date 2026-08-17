import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/token_storage.dart';

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.clearLocaleTestValue();
  });

  testWidgets('bootstrap falls back to the system locale when French', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('fr');
    final controller = LocaleController(storage: InMemoryTokenStorage());
    await controller.bootstrap();
    expect(controller.locale.languageCode, 'fr');
  });

  testWidgets('bootstrap falls back to English for any unsupported system locale', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('de');
    final controller = LocaleController(storage: InMemoryTokenStorage());
    await controller.bootstrap();
    expect(controller.locale.languageCode, 'en');
  });

  testWidgets('an explicit prior choice beats the system locale on bootstrap', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    final storage = InMemoryTokenStorage();
    await storage.write('spekooh_locale', 'fr');
    final controller = LocaleController(storage: storage);
    await controller.bootstrap();
    expect(controller.locale.languageCode, 'fr');
  });

  testWidgets('setLocale persists the choice for the next bootstrap', (tester) async {
    final storage = InMemoryTokenStorage();
    final controller = LocaleController(storage: storage);
    await controller.setLocale('fr');
    expect(controller.locale.languageCode, 'fr');
    expect(await storage.read('spekooh_locale'), 'fr');
  });

  testWidgets('syncFromAccount applies the account language when no explicit local choice exists', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    final controller = LocaleController(storage: InMemoryTokenStorage());
    await controller.bootstrap(); // system default, not explicit
    await controller.syncFromAccount('fr');
    expect(controller.locale.languageCode, 'fr');
  });

  testWidgets('syncFromAccount does not override a choice this device already made explicitly', (tester) async {
    final controller = LocaleController(storage: InMemoryTokenStorage());
    await controller.setLocale('en'); // explicit
    await controller.syncFromAccount('fr'); // account says fr, but device already chose
    expect(controller.locale.languageCode, 'en');
  });

  testWidgets('syncFromAccount is a no-op for a null or unsupported language_pref', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    final controller = LocaleController(storage: InMemoryTokenStorage());
    await controller.bootstrap();
    await controller.syncFromAccount(null);
    expect(controller.locale.languageCode, 'en');
    await controller.syncFromAccount('de');
    expect(controller.locale.languageCode, 'en');
  });
}
