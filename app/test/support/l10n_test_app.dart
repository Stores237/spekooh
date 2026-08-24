import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/l10n/app_localizations.dart';
import 'package:spekooh/theme/app_theme.dart';

/// Wraps [home] in a MaterialApp with the real AppLocalizations delegates
/// wired up (needed by any widget test that touches a screen using
/// AppLocalizations.of(context), or the `!` in that call throws) and,
/// mirroring main.dart's SpekoohApp, listens to LocaleController.instance
/// so a test that calls LocaleController.instance.setLocale(...) actually
/// sees the rebuild — same reactivity path as the real app.
Widget l10nTestApp(Widget home, {List<NavigatorObserver> navigatorObservers = const []}) {
  return ListenableBuilder(
    listenable: LocaleController.instance,
    builder: (context, _) => MaterialApp(
      theme: appTheme,
      locale: LocaleController.instance.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObservers,
      home: home,
    ),
  );
}
