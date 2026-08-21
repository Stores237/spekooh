import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'data/locale_controller.dart';
import 'data/offline_papers_store.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'shell/root_shell.dart';

void main() async {
  // Needed before LocaleController.bootstrap() can read the platform's
  // locale — previously only called on the !kIsWeb branch below, which
  // left web without a binding until runApp() implicitly created one,
  // too late for bootstrap() to use it.
  WidgetsFlutterBinding.ensureInitialized();
  // google_mobile_ads and OfflinePapersStore (path_provider) both have no
  // meaningful web implementation — the offline-download affordance is
  // gated behind !kIsWeb wherever it's shown, same as the rewarded ad.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    await OfflinePapersStore.instance.bootstrap();
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
