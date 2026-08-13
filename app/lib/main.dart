import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme/app_theme.dart';
import 'shell/root_shell.dart';

void main() async {
  // google_mobile_ads has no web implementation — initializing it there
  // would throw, and the rewarded-ad affordance is already gated behind
  // !kIsWeb wherever it's shown (see PaperDetailScreen).
  if (!kIsWeb) {
    WidgetsFlutterBinding.ensureInitialized();
    await MobileAds.instance.initialize();
  }
  runApp(const SpekoohApp());
}

class SpekoohApp extends StatelessWidget {
  const SpekoohApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spekooh',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const RootShell(),
    );
  }
}
