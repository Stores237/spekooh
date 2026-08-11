import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_theme.dart';

enum SpekoohBannerTone { green, blue }

/// Soft-tint inline callout. Green = reassurance/tips, blue = AI upsell
/// (renders gold-family per the token aliasing). Ported from
/// components/feedback/Banner.jsx.
class SpekoohBanner extends StatelessWidget {
  const SpekoohBanner({
    super.key,
    this.tone = SpekoohBannerTone.green,
    this.icon,
    required this.message,
    this.action,
  });

  final SpekoohBannerTone tone;
  final Widget? icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final bg = tone == SpekoohBannerTone.green ? AppColors.green100 : AppColors.blue100;
    final fg = tone == SpekoohBannerTone.green ? AppColors.green600 : AppColors.blue600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.radiusLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme.merge(data: IconThemeData(color: fg, size: 16), child: icon!),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: plusJakartaSansFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 10), action!],
        ],
      ),
    );
  }
}
