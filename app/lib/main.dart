import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'data/locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'shell/root_shell.dart';

void main() async {
  // Needed before LocaleController.bootstrap() can read the platform's
  // locale — previously only called on the !kIsWeb branch below, which
  // left web without a binding until runApp() implicitly created one,
  // too late for bootstrap() to use it.
  WidgetsFlutterBinding.ensureInitialized();
  // google_mobile_ads has no web implementation — initializing it there
  // would throw, and the rewarded-ad affordance is already gated behind
  // !kIsWeb wherever it's shown (see PaperDetailScreen).
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  await LocaleController.instance.bootstrap();
  runApp(const SpekoohApp());
}

class SpekoohApp extends StatelessWidget {
  const SpekoohApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) => MaterialApp(
        title: 'Spekooh',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        locale: LocaleController.instance.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const RootShell(),
      ),
    );
  }
}
