import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

/// Shown briefly on app launch, then hands off to [child]. Owner-supplied
/// logo (assets/branding/spekooh_logo.png) — placement/timing here is a
/// first pass, not a final design pass.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) return widget.child;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.goldSoft),
        child: Center(
          child: Image.asset(
            'assets/branding/spekooh_logo.png',
            width: 240,
          ),
        ),
      ),
    );
  }
}
