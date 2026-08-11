import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_theme.dart';

enum SpekoohBadgeTone { blue, amber, green, neutral, dark }

/// Uppercase pill label for metadata tags ("MOCK", "PAPER 2", "TRENDING").
/// Ported from components/core/Badge.jsx.
class SpekoohBadge extends StatelessWidget {
  const SpekoohBadge({super.key, required this.text, this.tone = SpekoohBadgeTone.blue});

  final String text;
  final SpekoohBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case SpekoohBadgeTone.blue:
        bg = AppColors.blue100;
        fg = AppColors.blue600;
      case SpekoohBadgeTone.amber:
        bg = AppColors.amber100;
        fg = AppColors.amber600;
      case SpekoohBadgeTone.green:
        bg = AppColors.green100;
        fg = AppColors.green600;
      case SpekoohBadgeTone.neutral:
        bg = AppColors.surfaceSunken;
        fg = AppColors.textSecondary;
      case SpekoohBadgeTone.dark:
        bg = AppColors.ink900;
        fg = AppColors.white;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.radiusPill),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: plusJakartaSansFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.04 * 11,
          color: fg,
          height: 1.0,
        ),
      ),
    );
  }
}
