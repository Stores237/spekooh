import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';
import '../widgets/heritage_pattern_strip.dart';

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
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/branding/spekooh_logo.png',
                width: 240,
              ),
            ),
            // Owner reference (2026-09-12): a real West African textile
            // border pattern, "just a representation... not the app design
            // itself... very less presence, not aggressive" — see
            // HeritagePatternStrip's own doc comment for why this is a
            // simplified, low-opacity single motif rather than the busy,
            // multi-row, high-contrast reference band itself.
            const Positioned(left: 0, right: 0, bottom: 32, child: HeritagePatternStrip()),
          ],
        ),
      ),
    );
  }
}
