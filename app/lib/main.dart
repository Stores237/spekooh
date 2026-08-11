import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'shell/root_shell.dart';

void main() {
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
